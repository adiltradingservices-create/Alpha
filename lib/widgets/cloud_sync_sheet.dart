import 'package:flutter/material.dart';
import '../services/cloud_sync_engine.dart';

class CloudSyncSheet extends StatelessWidget {
  const CloudSyncSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF030712),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const CloudSyncSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = CloudSyncEngine();

    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final pending = engine.pendingOperations;
        final isSyncing = engine.currentStatus == SyncStatus.syncing;

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF38BDF8), size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ENTERPRISE CLOUD RECONCILER", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                          Text("Offline-first transactional journal sync gateway", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E293B), height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSyncing ? "SYNCHRONIZING WITH CLOUD..." : (pending.isEmpty ? "ALL RECORDS RECONCILED" : "${pending.length} LOCAL TRANSACTIONS PENDING"),
                          style: TextStyle(
                            color: isSyncing ? const Color(0xFF38BDF8) : (pending.isEmpty ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          engine.lastSyncTime != null
                              ? "Last cloud flush: ${engine.lastSyncTime!.hour}:${engine.lastSyncTime!.minute.toString().padLeft(2, '0')}:${engine.lastSyncTime!.second.toString().padLeft(2, '0')}"
                              : "No sync flushes executed this session",
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 7),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: isSyncing
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.sync_rounded, color: Colors.black, size: 14),
                      label: Text(
                        isSyncing ? "SYNCING" : "SYNC NOW",
                        style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                      onPressed: isSyncing ? null : () => engine.flushQueue(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Text("LOCAL MUTATION JOURNAL QUEUE:", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),

              Expanded(
                child: pending.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF10B981).withValues(alpha: 0.5), size: 36),
                            const SizedBox(height: 6),
                            const Text("Local state is synchronized with remote store.", style: TextStyle(color: Color(0xFF64748B), fontSize: 8)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pending.length,
                        itemBuilder: (ctx, idx) {
                          final item = pending[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF1E293B)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.outbox_rounded, color: Color(0xFFF59E0B), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${item.action} • ${item.entity}",
                                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "ID: ${item.id} • ${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}",
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 7),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text("QUEUED", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 6.5, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
