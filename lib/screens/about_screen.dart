import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../build_info.dart';
import '../theme/app_tokens.dart';
import '../widgets/neo_back_button.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/ui_kit.dart';

/// Everything about Wombat: what it is, what it can do, how it treats your
/// data, where to find it — and the exact build (git commit) you're running.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _repoUrl = 'https://github.com/ryandam9/Wombat';
  static const _openRouterUrl = 'https://openrouter.ai';
  static const _keysUrl = 'https://openrouter.ai/keys';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: NeoBackButton.leading(context),
        title: const Text('About'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              for (final (i, section) in _sections(context).indexed)
                StaggeredEntrance(
                  index: i,
                  bounce: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: section,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context) => [
        const _Hero(),
        SectionPanel(
          title: 'Build',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LabelValueRow(
                label: 'Version',
                value: BuildInfo.version,
              ),
              _commitRow(context),
              if (BuildInfo.commitDate != 'unknown')
                const LabelValueRow(
                  label: 'Commit date',
                  value: BuildInfo.commitDate,
                ),
              if (BuildInfo.branch != 'unknown')
                const LabelValueRow(label: 'Branch', value: BuildInfo.branch),
              LabelValueRow(label: 'Platform', value: _platformName()),
              const LabelValueRow(label: 'Framework', value: 'Flutter · Material 3'),
            ],
          ),
        ),
        const SectionPanel(
          title: 'What it is',
          child: Text(
            'Wombat is a cross-platform Flutter app for chatting with large '
            'language models through OpenRouter. With a single OpenRouter API '
            'key you get one chat interface over hundreds of models from '
            'OpenAI, Anthropic, Google, Meta, Mistral and more — with streaming '
            'replies, saved conversations, live usage and cost tracking, and a '
            'clean Material 3 interface.\n\n'
            'It is a thin, native client: you bring your own key and requests go '
            'straight from your device to OpenRouter — never through a server of '
            'ours.',
            style: TextStyle(height: 1.45),
          ),
        ),
        const SectionPanel(
          title: 'Features',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Feature(
                icon: Icons.bolt_outlined,
                title: 'Streaming chat',
                subtitle:
                    'Token-by-token replies over SSE; stop a response mid-stream.',
              ),
              _Feature(
                icon: Icons.attachment_outlined,
                title: 'Multimodal',
                subtitle:
                    'Send images, audio (incl. in-app recording) and PDFs; render '
                    'generated images, inline SVG and audio replies.',
              ),
              _Feature(
                icon: Icons.grid_view_outlined,
                title: 'Live model picker',
                subtitle:
                    'OpenRouter catalogue with search, a free-only filter, sort, '
                    'and custom model IDs.',
              ),
              _Feature(
                icon: Icons.insights_outlined,
                title: 'Usage & cost tracking',
                subtitle:
                    'Per-session tokens, USD cost, a per-model breakdown and your '
                    'account balance.',
              ),
              _Feature(
                icon: Icons.save_alt_outlined,
                title: 'Save output',
                subtitle:
                    'Save replies, generated images and audio to a folder or the '
                    'share sheet.',
              ),
              _Feature(
                icon: Icons.storage_outlined,
                title: 'On-device history',
                subtitle:
                    'Conversations persist in a local SQLite database, grouped by '
                    'recency.',
              ),
              _Feature(
                icon: Icons.palette_outlined,
                title: 'Theming',
                subtitle:
                    'Light / dark / system, a custom accent and background tint, '
                    'and selectable fonts.',
                last: true,
              ),
            ],
          ),
        ),
        const SectionPanel(
          title: 'Your data & privacy',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bullet('Conversations, messages and attachments stay on your '
                  'device in a local SQLite database.'),
              _Bullet('Your API key is held in the platform secure store '
                  '(Android Keystore / Linux libsecret / macOS Keychain).'),
              _Bullet('Usage and cost totals are in-memory only and reset on '
                  'restart.'),
              _Bullet('Nothing is sent anywhere but OpenRouter — requests go '
                  'straight from your device.', last: true),
            ],
          ),
        ),
        const SectionPanel(
          title: 'Links',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LinkTile(
                icon: Icons.hub_outlined,
                label: 'OpenRouter',
                url: _openRouterUrl,
              ),
              _LinkTile(
                icon: Icons.key_outlined,
                label: 'Get an API key',
                url: _keysUrl,
              ),
              _LinkTile(
                icon: Icons.code,
                label: 'Source code on GitHub',
                url: _repoUrl,
                last: true,
              ),
            ],
          ),
        ),
      ];

  Widget _commitRow(BuildContext context) {
    if (!BuildInfo.hasCommit) {
      return const LabelValueRow(label: 'Commit', value: 'unknown');
    }
    return const LabelValueRow(
      label: 'Commit',
      trailing: _CopyableCommit(
        short: BuildInfo.commit,
        full: BuildInfo.commitFull,
      ),
    );
  }

  static String _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }
}

/// The header: app icon, name, tagline and a version badge leading with the
/// git commit.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border:
            Border.all(color: scheme.outlineVariant, width: AppTokens.border),
        boxShadow: AppTokens.softShadow(scheme, level: 1),
      ),
      child: Column(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.pets, size: 64, color: scheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text('Wombat',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Chat with hundreds of LLMs through OpenRouter',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          StatusChip(BuildInfo.displayVersion),
        ],
      ),
    );
  }
}

/// The commit value as a tappable chip that copies the full hash.
class _CopyableCommit extends StatelessWidget {
  const _CopyableCommit({required this.short, required this.full});

  final String short;
  final String full;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mono = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      onTap: () {
        Clipboard.setData(ClipboardData(text: full));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commit hash copied'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(short,
                style: mono?.copyWith(
                    color: scheme.primary, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Icon(Icons.copy, size: 14, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// A feature row: leading icon, bold title and a short description.
class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A privacy bullet point with an accent dot.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text, {this.last = false});

  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// A tappable external link row that opens [url] in the browser.
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.url,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String url;
  final bool last;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(url);
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.open_in_new,
                    size: 16, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
