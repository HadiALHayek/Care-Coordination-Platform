import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/language_provider.dart';
import '../../core/constants/prefs_cache.dart';
import '../../services/chat_api.dart';
import '../../services/prescription_api.dart';

class ChatView extends StatefulWidget {
  final int recipientId;
  final String recipientName;

  const ChatView({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  late int myId;
  late String token;

  bool _isDoctor = false;

  int? _lastScanId;
  bool _sendingReport = false;
  bool _reportAlreadySent = false;

  final TextEditingController _drugController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _freqController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _sendingRx = false;

  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _loadUserAndState();
  }

  Future<void> _loadUserAndState() async {
    final prefs = await PrefsCache.getInstance();

    token = prefs.getString("token") ?? "";
    myId = prefs.getInt("user_id") ?? 0;

    final userType = prefs.getString("user_type") ?? "patient";
    _isDoctor = userType == "doctor";

    _lastScanId = prefs.getInt("last_scan_id");

    if (_lastScanId != null) {
      _reportAlreadySent =
          prefs.getBool("pdf_sent_${widget.recipientId}_scan_$_lastScanId") ??
          false;
    } else {
      _reportAlreadySent = false;
    }

    await _loadMessages();

    // ✅ connect websocket AFTER token is loaded
    _connectWebSocket();

    if (mounted) setState(() {});
    _scrollToBottom();
  }

  // ----------------------------
  // WebSocket connect + listen
  // ----------------------------
  void _connectWebSocket() {
    // Close any previous connection
    _wsSub?.cancel();
    _ws?.sink.close();

    // ✅ Define wsUrl here (same scope)
    final wsUrl =
        "ws://192.168.1.10:8001/ws/chat/${widget.recipientId}/?token=$token";
    debugPrint("WS URL USED => $wsUrl");
    _ws = WebSocketChannel.connect(Uri.parse(wsUrl));

    _wsSub = _ws!.stream.listen(
      (data) {
        try {
          final msg = jsonDecode(data);

          if (msg is Map && msg["type"] == "chat_message") {
            final incoming = Map<String, dynamic>.from(msg);

            final senderId = incoming["sender_id"];
            final recipientId = incoming["recipient_id"];
            final isForThisThread =
                (senderId == widget.recipientId && recipientId == myId) ||
                (senderId == myId && recipientId == widget.recipientId);

            if (!isForThisThread) return;

            final incomingId = incoming["id"];
            final exists = messages.any((m) => m["id"] == incomingId);
            if (!exists) {
              if (mounted) {
                setState(() => messages = [...messages, incoming]);
                _scrollToBottom();
              }
            }
          }
        } catch (_) {}
      },
      onError: (e) {},
      onDone: () {},
    );
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadMessages() async {
    final list = await ChatApi.getMessages(
      otherUserId: widget.recipientId,
      token: token,
    );
    if (!mounted) return;
    setState(() => messages = list);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Optimistic UI (shows instantly)
    final optimistic = {
      "id": "tmp_${DateTime.now().millisecondsSinceEpoch}",
      "sender_id": myId,
      "recipient_id": widget.recipientId,
      "message": text,
      "pdf_url": null,
      "timestamp": DateTime.now().toIso8601String(),
    };

    setState(() => messages = [...messages, optimistic]);
    _scrollToBottom();

    _controller.clear();

    final ok = await ChatApi.sendMessage(
      recipientId: widget.recipientId,
      message: text,
      token: token,
    );

    if (!ok) {
      // If send failed, reload from server so UI is consistent
      await _loadMessages();
      return;
    }

    // If send succeeded, backend will push via WS to the recipient.
    // We can also refresh once to replace the optimistic "tmp" message with real id:
    await _loadMessages();
    _scrollToBottom();
  }

  // ✅ patient: Send AI PDF report to doctor
  Future<void> _sendAiReportToDoctor() async {
    if (_sendingReport) return;

    if (_lastScanId == null || _lastScanId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No scan found to send. Upload a scan first."),
        ),
      );
      return;
    }

    setState(() => _sendingReport = true);

    try {
      final res = await ChatApi.sendReportToDoctor(
        doctorId: widget.recipientId,
        scanId: _lastScanId!,
        token: token,
      );

      if (!mounted) return;

      final ok = res["success"] == true;
      final detail =
          (res["detail"] ?? res["message"] ?? res["error"] ?? "").toString();

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(detail.isNotEmpty ? detail : "Failed to send report"),
          ),
        );
        return;
      }

      final prefs = await PrefsCache.getInstance();
      await prefs.setBool(
        "pdf_sent_${widget.recipientId}_scan_$_lastScanId",
        true,
      );

      setState(() => _reportAlreadySent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI report sent to doctor ✅")),
      );

      await _loadMessages();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _sendingReport = false);
    }
  }

  // ✅ doctor: prescription sheet (unchanged)
  Future<void> _openPrescriptionSheet() async {
    _drugController.clear();
    _dosageController.clear();
    _freqController.clear();
    _durationController.clear();
    _notesController.clear();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Write Prescription",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _drugController,
                    decoration: const InputDecoration(labelText: "Drug name *"),
                  ),
                  TextField(
                    controller: _dosageController,
                    decoration: const InputDecoration(labelText: "Dosage"),
                  ),
                  TextField(
                    controller: _freqController,
                    decoration: const InputDecoration(labelText: "Frequency"),
                  ),
                  TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(labelText: "Duration"),
                  ),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: "Notes"),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _sendingRx
                              ? null
                              : () async {
                                final drug = _drugController.text.trim();
                                if (drug.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Drug name is required"),
                                    ),
                                  );
                                  return;
                                }

                                setLocal(() => _sendingRx = true);

                                try {
                                  final res =
                                      await PrescriptionApi.createPrescription(
                                        token: token,
                                        patientId: widget.recipientId,
                                        notes: _notesController.text.trim(),
                                        items: [
                                          {
                                            "drug_name": drug,
                                            "dosage":
                                                _dosageController.text.trim(),
                                            "frequency":
                                                _freqController.text.trim(),
                                            "duration":
                                                _durationController.text.trim(),
                                          },
                                        ],
                                      );

                                  if (!mounted) return;

                                  if (res["success"] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Prescription sent to pharmacy ✅",
                                        ),
                                      ),
                                    );
                                    Navigator.of(ctx).pop();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Failed: ${res["error"]}",
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted)
                                    setLocal(() => _sendingRx = false);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF20BCD0),
                        foregroundColor: Colors.white,
                      ),
                      child:
                          _sendingRx
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text("Send to Preferred Pharmacy"),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map msg, {Key? key}) {
    final bool isMe = msg["sender_id"] == myId;

    return Align(
      key: key,
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (msg["message"] != null && msg["message"].toString().isNotEmpty)
              Text(
                msg["message"].toString(),
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 6),
            if (msg["pdf_url"] != null)
              GestureDetector(
                onTap: () => context.push('/pdf-viewer', extra: msg["pdf_url"]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 6),
                    Text(
                      "Open Report",
                      style: TextStyle(
                        color: Colors.red,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reportBanner() {
    if (_isDoctor) return const SizedBox();
    if (_lastScanId == null || _lastScanId == 0) return const SizedBox();

    final disabled = _reportAlreadySent || _sendingReport;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: ElevatedButton.icon(
        onPressed: disabled ? null : _sendAiReportToDoctor,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              disabled ? Colors.grey.shade400 : const Color(0xFF20BCD0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon:
            _sendingReport
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.picture_as_pdf),
        label: Text(
          _reportAlreadySent ? "AI Report Sent ✅" : "Send AI Report (PDF)",
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws?.sink.close();

    _scroll.dispose();
    _controller.dispose();
    _drugController.dispose();
    _dosageController.dispose();
    _freqController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<LanguageProvider, String>(
      selector: (_, provider) => provider.language,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.recipientName),
            backgroundColor: const Color(0xFF20BCD0),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (_isDoctor)
                IconButton(
                  icon: const Icon(Icons.medication, color: Colors.white),
                  onPressed: _openPrescriptionSheet,
                  tooltip: "Write Drug",
                ),
            ],
          ),
          body: Column(
            children: [
              _reportBanner(),
              Expanded(
                child:
                    messages.isEmpty
                        ? const Center(child: Text("Start messaging..."))
                        : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _buildMessageBubble(
                              message,
                              key: ValueKey('msg_${message['id'] ?? index}'),
                            );
                          },
                        ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText:
                              lang == 'English'
                                  ? 'Type message...'
                                  : 'اكتب رسالة...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      backgroundColor: const Color(0xFF20BCD0),
                      onPressed: _sendMessage,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
