import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/ai_chat_diagnostics.dart';
import '../../core/services/chat_history_store.dart';
import 'ai_chat_activity_screen.dart';
import '../emotion_result/models/emotion_analysis.dart';

class EmotionChatScreen extends StatefulWidget {
  const EmotionChatScreen({super.key, this.analysis});
  final EmotionAnalysis? analysis;

  @override
  State<EmotionChatScreen> createState() => _EmotionChatScreenState();
}

class _ChatMessage {
  const _ChatMessage(this.text, this.fromUser, {this.localFallback = false});
  final String text;
  final bool fromUser;
  final bool localFallback;
}

class _EmotionChatScreenState extends State<EmotionChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  late final ChatHistoryStore _history;
  late final GenerativeModel _model;
  late ChatSession _chat;
  bool _sending = false;
  bool _loading = true;
  String? _retryText;
  String _streamingText = '';
  int _messageRevision = 0;

  @override
  void initState() {
    super.initState();
    _history = ChatHistoryStore(analysisId: widget.analysis?.id);
    final analysis = widget.analysis;
    final resultContext = analysis == null
        ? ''
        : ' The optional app context is an on-device facial-expression estimate: '
              '${analysis.emotion}, model score ${(analysis.confidence * 100).round()}%. '
              'This is uncertain and does not measure actual feelings.';
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite',
      systemInstruction: Content.system(
        'You are a kind, practical emotional-wellbeing reflection assistant in EmoSense AI. '
        'Offer short, non-judgmental support and simple everyday coping ideas. Never diagnose, '
        'provide medical treatment, or claim a facial expression reveals a true feeling. '
        'Encourage professional or emergency help when the user describes serious risk.'
        '$resultContext',
      ),
      generationConfig: GenerationConfig(
        maxOutputTokens: 240,
        temperature: 0.7,
      ),
    );
    _chat = _model.startChat();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final loaded = await _history.loadLocal();
    if (!mounted) return;
    _applyHistory(loaded);
    setState(() => _loading = false);
    _scrollToBottom();
    unawaited(_syncHistory());
  }

  Future<void> _syncHistory() async {
    final revisionAtStart = _messageRevision;
    final loaded = await _history.syncCloud();
    if (!mounted || _sending || revisionAtStart != _messageRevision) return;
    setState(() {
      _messages.clear();
      _retryText = null;
      _applyHistory(loaded);
    });
    _scrollToBottom();
  }

  void _applyHistory(List<Map<String, dynamic>> loaded) {
    final contents = <Content>[];
    String? unansweredUserTurn;
    for (final item in loaded) {
      final role = item['role'] as String?;
      final text = item['text'] as String? ?? '';
      final localFallback = item['localFallback'] == true;
      if (role == 'user') {
        _messages.add(_ChatMessage(text, true));
        unansweredUserTurn = text;
      } else if (role == 'model' && !localFallback) {
        _messages.add(_ChatMessage(text, false));
        if (unansweredUserTurn != null) {
          contents.add(Content.text(unansweredUserTurn));
          contents.add(Content.model([TextPart(text)]));
          unansweredUserTurn = null;
        }
      } else if (localFallback) {
        _messages.add(_ChatMessage(text, false, localFallback: true));
        _retryText = unansweredUserTurn;
        unansweredUserTurn = null;
      }
    }
    _retryText ??= unansweredUserTurn;
    _chat = _model.startChat(history: contents);
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    await _sendText(text, addUser: true);
  }

  Future<void> _retry() async {
    final text = _retryText;
    if (text == null || _sending) return;
    setState(() {
      _messages.removeWhere((message) => message.localFallback);
      _retryText = null;
    });
    await _sendText(text, addUser: false);
  }

  Future<void> _sendText(String text, {required bool addUser}) async {
    _messageRevision++;
    setState(() {
      _sending = true;
      _streamingText = '';
      if (addUser) _messages.add(_ChatMessage(text, true));
    });
    if (addUser) {
      try {
        await _history.add('user', text);
      } catch (error) {
        debugPrint('Could not store chat prompt locally: $error');
      }
    }
    _scrollToBottom();
    final timer = Stopwatch()..start();
    unawaited(AiChatDiagnostics.record('Request started'));
    var reply = '';
    var receivedFirstText = false;
    final waitingNotice = Timer(const Duration(seconds: 12), () {
      if (!mounted || receivedFirstText || !_sending) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Still connecting to the assistant. Please check your internet if this continues.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
    try {
      final stream = _chat
          .sendMessageStream(Content.text(text))
          .timeout(
            const Duration(seconds: 45),
            onTimeout: (sink) => sink.addError(
              TimeoutException('No response received within 45 seconds.'),
            ),
          );
      await for (final chunk in stream) {
        final part = chunk.text;
        if (part == null || part.isEmpty) continue;
        reply += part;
        if (!receivedFirstText) {
          receivedFirstText = true;
          waitingNotice.cancel();
          unawaited(
            AiChatDiagnostics.record(
              'First text received',
              detail: '${timer.elapsedMilliseconds} ms after sending',
            ),
          );
        }
        if (!mounted) return;
        setState(() => _streamingText = reply);
        _scrollToBottom();
      }
      reply = reply.trim();
      if (reply.isEmpty) throw StateError('The model returned no text.');
      try {
        await _history.add('model', reply);
      } catch (error) {
        debugPrint('Could not store AI reply locally: $error');
      }
      unawaited(
        AiChatDiagnostics.record(
          'Reply completed',
          detail:
              '${timer.elapsedMilliseconds} ms · ${reply.length} characters',
        ),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(reply, false));
        _streamingText = '';
        _retryText = null;
      });
    } catch (error, stack) {
      debugPrint('Emotion chat request failed: $error\n$stack');
      if (!mounted) return;
      final errorText = error.toString().toLowerCase();
      final networkIssue =
          error is TimeoutException ||
          errorText.contains('network') ||
          errorText.contains('socket') ||
          errorText.contains('connection') ||
          errorText.contains('unavailable') ||
          errorText.contains('deadline');
      unawaited(
        AiChatDiagnostics.record(
          'Request failed',
          detail:
              '${error.runtimeType} · ${networkIssue ? 'network or timeout' : 'service error'} · ${timer.elapsedMilliseconds} ms',
        ),
      );
      if (reply.trim().isNotEmpty) {
        final partial = reply.trim();
        try {
          await _history.add('model', partial);
        } catch (_) {}
        if (!mounted) return;
        setState(() => _messages.add(_ChatMessage(partial, false)));
      }
      const fallback =
          'I’m here with you. Try one slow breath, then name one thing you can see, one sound you can hear, and one thing you can feel. You can try your message again whenever you’re ready.';
      try {
        await _history.add('local', fallback, localFallback: true);
      } catch (storageError) {
        debugPrint('Could not store local chat support: $storageError');
      }
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(fallback, false, localFallback: true));
        _streamingText = '';
        _retryText = text;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              networkIssue
                  ? 'Connection issue. Check your internet and try again.'
                  : 'The reply could not finish. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'Retry', onPressed: () => _retry()),
          ),
        );
    } finally {
      waitingNotice.cancel();
      if (mounted) {
        setState(() {
          _sending = false;
          _streamingText = '';
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff0F172A),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Emotion Support Chat',
        style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          tooltip: 'AI chat activity log',
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AiChatActivityScreen(),
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff1E293B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Your messages${widget.analysis == null ? '' : ' and the selected expression label'} are sent to Gemini through Firebase AI Logic; photos are never sent. Google may use free-tier prompts to improve its products. Avoid sharing identifying or sensitive details.',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
          if (widget.analysis != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xff2563EB).withValues(alpha: .16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Color(0xff93C5FD),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'About: ${widget.analysis!.emotion} · ${(widget.analysis!.confidence * 100).round()}% model score',
                    style: GoogleFonts.poppins(
                      color: const Color(0xffBFDBFE),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: _AssistantTypingBubble(label: 'Opening chat'),
                  )
                : _messages.isEmpty
                ? _welcome()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_sending && index == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: _AssistantTypingBubble(
                            label: _streamingText.isEmpty
                                ? 'Thinking'
                                : 'Replying',
                            text: _streamingText,
                          ),
                        );
                      }
                      final message = _messages[index];
                      return Align(
                        alignment: message.fromUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: message.fromUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              constraints: const BoxConstraints(maxWidth: 310),
                              decoration: BoxDecoration(
                                color: message.fromUser
                                    ? const Color(0xff2563EB)
                                    : const Color(0xff1E293B),
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: Text(
                                message.text,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            if (message.localFallback && _retryText != null)
                              TextButton.icon(
                                onPressed: _sending ? null : _retry,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Try again'),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1200,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Ask for a supportive idea…',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xff1E293B),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 9),
                IconButton.filled(
                  onPressed: _sending || _loading ? null : () => _send(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xff2563EB),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _welcome() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: Color(0xff60A5FA),
          ),
          const SizedBox(height: 14),
          Text(
            'A supportive space to reflect',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask for a simple grounding idea, or ask what a model score means. This assistant cannot diagnose or know how you truly feel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          if (widget.analysis != null)
            OutlinedButton(
              onPressed: _sending
                  ? null
                  : () => _send(
                      'Can you explain this expression estimate and suggest one gentle, practical thing I could try?',
                    ),
              child: const Text('Explain this result'),
            ),
        ],
      ),
    ),
  );
}

class _AssistantTypingBubble extends StatelessWidget {
  const _AssistantTypingBubble({this.label = 'Thinking', this.text = ''});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    constraints: const BoxConstraints(maxWidth: 310),
    decoration: BoxDecoration(
      color: const Color(0xff1E293B),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xff60A5FA).withValues(alpha: .16)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (text.isNotEmpty) ...[
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xff8B5CF6), Color(0xff3B82F6)],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10),
            ),
            const SizedBox(width: 8),
            const _PulsingDots(),
          ],
        ),
      ],
    ),
  );
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _scales;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();
    _scales = List.generate(3, (index) {
      final pause = index * 15.0;
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: ConstantTween(.55),
          weight: pause == 0 ? 1 : pause,
        ),
        TweenSequenceItem(tween: Tween(begin: .55, end: 1.0), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: .55), weight: 20),
        TweenSequenceItem(tween: ConstantTween(.55), weight: 59 - pause),
      ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      3,
      (index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ScaleTransition(
          scale: _scales[index],
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xff93C5FD),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ),
  );
}
