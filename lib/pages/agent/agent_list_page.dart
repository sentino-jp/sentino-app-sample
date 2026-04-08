import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// 智能体列表页
class AgentListPage extends StatelessWidget {
  const AgentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.agent)),
      body: Center(child: Text(l.agent)),
    );
  }
}
