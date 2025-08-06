import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData) {
          return SignInScreen(
            providers: [EmailAuthProvider()],
            actions: [
              AuthStateChangeAction((ctx, state) {
                if (state is SignedIn) {
                  Navigator.of(ctx).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CaosBox()),
                  );
                }
              })
            ],
          );
        }
        return const CaosBox();
      },
    );
  }
}

/* ===== MODELOS / ENUMS ===== */
enum ItemType { idea, action }
enum ItemStatus { normal, completed, archived }
enum FilterMode { off, include, exclude }
enum FilterKey { completed, archived, hasLinks }

class Item {
  final String id, text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt, modifiedAt;
  final int statusChanges;
  Item(this.id, this.text, this.type,
      [this.status = ItemStatus.normal,
      DateTime? c,
      DateTime? m,
      this.statusChanges = 0])
      : createdAt = c ?? DateTime.now(),
        modifiedAt = m ?? DateTime.now();
  Item copyWith({ItemStatus? status}) {
    final ns = status ?? this.status;
    final chg = ns != this.status;
    return Item(id, text, type, ns, createdAt,
        chg ? DateTime.now() : modifiedAt, chg ? statusChanges + 1 : statusChanges);
  }
}

extension DateFmt on DateTime {
  String two(int n) => n.toString().padLeft(2, '0');
  String get f =>
      '${two(day)}/${two(month)}/${year} ${two(hour)}:${two(minute)}';
}

extension StatusName on ItemStatus {
  String get name => switch (this) {
        ItemStatus.normal => 'Normal',
        ItemStatus.completed => 'Completado ✓',
        ItemStatus.archived => 'Archivado 📁'
      };
}

/* ===== ESTADO ===== */
class AppState extends ChangeNotifier {
  final _items = <ItemType, List<Item>>{
    ItemType.idea: [],
    ItemType.action: []
  };
  final _links = <String, Set<String>>{};
  final _cnt = <ItemType, int>{ItemType.idea: 0, ItemType.action: 0};
  final _cache = <String, Item>{};
  final _notes = <String, String>{};

  String note(String id) => _notes[id] ?? '';
  void setNote(String id, String v) {
    _notes[id] = v;
    notifyListeners();
  }

  List<Item> items(ItemType t) => List.unmodifiable(_items[t]!);
  List<Item> get all => _items.values.expand((e) => e).toList();
  Set<String> links(String id) => _links[id] ?? {};
  Item? getItem(String id) => _cache[id];

  void add(ItemType t, String text) {
    final v = text.trim();
    if (v.isEmpty) return;
    _cnt[t] = (_cnt[t] ?? 0) + 1;
    final prefix = t == ItemType.idea ? 'B1' : 'B2';
    final id = '$prefix${_cnt[t]!.toString().padLeft(3, '0')}';
    _items[t]!.insert(0, Item(id, v, t));
    _reindex();
    notifyListeners();
  }

  bool _up(String id, Item Function(Item) ch) {
    final it = _cache[id];
    if (it == null) return false;
    final L = _items[it.type]!;
    final idx = L.indexWhere((e) => e.id == id);
    if (idx < 0) return false;
    L[idx] = ch(it);
    _reindex();
    notifyListeners();
    return true;
  }

  bool setStatus(String id, ItemStatus s) => _up(id, (it) => it.copyWith(status: s));
  bool updateText(String id, String t) =>
      _up(id, (it) => Item(it.id, t, it.type, it.status, it.createdAt, DateTime.now(), it.statusChanges));

  void toggleLink(String a, String b) {
    if (a == b || _cache[a] == null || _cache[b] == null) return;
    final sa = _links.putIfAbsent(a, () => <String>{});
    final sb = _links.putIfAbsent(b, () => <String>{});
    if (sa.remove(b)) {
      sb.remove(a);
    } else {
      sa.add(b);
      sb.add(a);
    }
    notifyListeners();
  }

  void _reindex() {
    _cache
      ..clear()
      ..addAll({for (final it in all) it.id: it});
  }
}

/* ===== ESTILOS ===== */
class Style {
  static const title = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const id = TextStyle(
      fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500);
  static const content = TextStyle(fontSize: 14);
  static const info = TextStyle(fontWeight: FontWeight.w600);
  static BoxDecoration get card => BoxDecoration(
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(8));
  static const statusIcons = {
    ItemStatus.completed: {'icon': Icons.check, 'color': Colors.green},
    ItemStatus.archived: {'icon': Icons.archive, 'color': Colors.grey},
  };
}

/* ===== FILTROS ===== */
class FilterSet {
  final text = TextEditingController();
  final modes = <FilterKey, FilterMode>{
    FilterKey.completed: FilterMode.off,
    FilterKey.archived: FilterMode.off,
    FilterKey.hasLinks: FilterMode.off
  };
  void dispose() => text.dispose();
  void setDefaults(Map<FilterKey, FilterMode> d) {
    clear();
    d.forEach((k, v) => modes[k] = v);
  }

  void cycle(FilterKey k) =>
      modes[k] = FilterMode.values[(modes[k]!.index + 1) % 3];

  void clear() {
    text.clear();
    for (final k in modes.keys) modes[k] = FilterMode.off;
  }

  bool get hasActive =>
      text.text.isNotEmpty || modes.values.any((m) => m != FilterMode.off);
}

class FilterEngine {
  static bool _pass(FilterMode m, bool v) => switch (m) {
        FilterMode.off => true,
        FilterMode.include => v,
        FilterMode.exclude => !v
      };
  static List<Item> apply(List<Item> items, AppState s, FilterSet set) {
    final q = set.text.text.toLowerCase();
    final hasQ = q.isNotEmpty;
    return items.where((it) {
      if (hasQ && !'${it.id} ${it.text}'.toLowerCase().contains(q)) {
        return false;
      }
      return _pass(set.modes[FilterKey.completed]!, it.status == ItemStatus.completed) &&
          _pass(set.modes[FilterKey.archived]!, it.status == ItemStatus.archived) &&
          _pass(set.modes[FilterKey.hasLinks]!, s.links(it.id).isNotEmpty);
    }).toList();
  }
}

/* ===== WIDGETS REUTILIZABLES ===== */
class ComposerCard extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController c;
  final VoidCallback onAdd, onCancel;
  const ComposerCard(
      {super.key,
      required this.icon,
      required this.hint,
      required this.c,
      required this.onAdd,
      required this.onCancel});
  @override
  Widget build(BuildContext ctx) {
    return Container(
      decoration: Style.card,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: LayoutBuilder(builder: (bCtx, cons) {
                final mq = MediaQuery.of(bCtx),
                    base = DefaultTextStyle.of(bCtx).style,
                    fs = base.fontSize ?? 14.0,
                    lh = fs * (base.height ?? 1.2);
                final hAvail = cons.maxHeight.isFinite
                    ? cons.maxHeight
                    : (mq.size.height - mq.viewInsets.bottom);
                final frac =
                    mq.orientation == Orientation.portrait ? 0.33 : 0.50;
                final cap = (hAvail * frac).clamp(lh, double.infinity);
                final maxL = (cap / lh).floor().clamp(1, 1000);
                return TextField(
                  controller: c,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: maxL,
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: ''),
                );
              }),
            ),
            Positioned(left: 0, top: 0, child: Icon(icon)),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: c,
              builder: (_, v, __) => v.text.isEmpty
                  ? const Positioned(
                      left: 28,
                      top: 0,
                      child:
                          Text('', style: TextStyle(color: Colors.black54)))
                  : const SizedBox.shrink(),
            ),
          ]),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowSpacing: 8,
              children: [
                TextButton(onPressed: onCancel, child: const Text('Cancelar')),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: c,
                  builder: (_, v, __) => ElevatedButton(
                      onPressed:
                          v.text.trim().isNotEmpty ? onAdd : null,
                      child: const Text('Agregar')),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class ChipsPanel extends StatelessWidget {
  final FilterSet set;
  final VoidCallback onUpdate;
  final Map<FilterKey, FilterMode>? defaults;
  const ChipsPanel(
      {super.key, required this.set, required this.onUpdate, this.defaults});
  @override
  Widget build(BuildContext ctx) {
    Widget chip(FilterKey k, String label) {
      final m = set.modes[k]!, active = m != FilterMode.off;
      final col = active
          ? (m == FilterMode.include
                  ? Colors.green
                  : Colors.red)
              .withOpacity(0.3)
          : null;
      final txt = m == FilterMode.exclude ? '⊘$label' : label;
      return FilterChip(
          label: Text(txt),
          selected: active,
          selectedColor: col,
          onSelected: (_) {
            set.cycle(k);
            onUpdate();
          });
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: set.text,
        onChanged: (_) => onUpdate(),
        decoration: const InputDecoration(
            hintText: 'Buscar...',
            prefixIcon: Icon(Icons.search),
            isDense: true),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        chip(FilterKey.completed, '✓'),
        chip(FilterKey.archived, '↓'),
        chip(FilterKey.hasLinks, '~'),
        if (set.hasActive)
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              if (defaults != null) {
                set.setDefaults(defaults!);
              } else {
                set.clear();
              }
              onUpdate();
            },
          ),
      ])
    ]);
  }
}

class ItemCard extends StatelessWidget {
  final Item it;
  final AppState st;
  final bool ex, showL, cbL, cbR, ck;
  final VoidCallback onT, onInfo;
  final VoidCallback? onTapCb;
  const ItemCard(
      {super.key,
      required this.it,
      required this.st,
      required this.ex,
      required this.onT,
      required this.onInfo,
      this.showL = true,
      this.cbL = false,
      this.cbR = false,
      this.ck = false,
      this.onTapCb});
  @override
  Widget build(BuildContext c) {
    final m = Style.statusIcons[it.status];
    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) => Behavior.swipe(d, it.status,
          (s) => st.setStatus(it.id, s)),
      background: Behavior.bg(false),
      secondaryBackground: Behavior.bg(true),
      child: Container(
        decoration: Style.card,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onInfo,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cbL)
                  Checkbox(
                      value: ck,
                      onChanged: onTapCb != null ? (_) => onTapCb!() : null),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (m != null)
                          Icon(m['icon'] as IconData,
                              color: m['color'] as Color, size: 16),
                        if (showL && st.links(it.id).isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.link,
                                color: Colors.blue, size: 16),
                          ),
                        const SizedBox(width: 6),
                        Flexible(child: Text(it.id, style: Style.id)),
                        const Spacer(),
                      ]),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: onT,
                        child: Text(
                          it.text,
                          maxLines: ex ? null : 1,
                          overflow:
                              ex ? null : TextOverflow.ellipsis,
                          style: Style.content,
                        ),
                      )
                    ],
                  ),
                ),
                if (cbR)
                  Checkbox(
                      value: ck,
                      onChanged: onTapCb != null ? (_) => onTapCb!() : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Behavior {
  static Future<bool> swipe(
          DismissDirection d, ItemStatus s, Function(ItemStatus) on) async =>
      on(d == DismissDirection.startToEnd
              ? (s == ItemStatus.completed
                  ? ItemStatus.normal
                  : ItemStatus.completed)
              : (s == ItemStatus.archived
                  ? ItemStatus.normal
                  : ItemStatus.archived)) ==
              null
          ? false
          : false;

  static Widget bg(bool sec) => Container(
        color:
            (sec ? Colors.grey : Colors.green).withOpacity(0.2),
        child: Align(
          alignment:
              sec ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(sec ? Icons.archive : Icons.check,
                color: sec ? Colors.grey : Colors.green),
          ),
        ),
      );
}

/* ===== MODAL INFO ===== */
String lbl(ItemType t) => t == ItemType.idea ? 'Idea' : 'Acción';
IconData ico(ItemType t) =>
    t == ItemType.idea ? Icons.lightbulb : Icons.assignment;

void showInfoModal(BuildContext c, Item it, AppState s) {
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => InfoModal(id: it.id, st: s),
  );
}

class InfoModal extends StatefulWidget {
  final String id;
  final AppState st;
  const InfoModal({super.key, required this.id, required this.st});
  @override
  State<InfoModal> createState() => _InfoModalState();
}

class _InfoModalState extends State<InfoModal> {
  late final TextEditingController ed;
  late final TextEditingController note;
  Timer? _deb, _debN;

  @override
  void initState() {
    super.initState();
    ed = TextEditingController(text: widget.st.getItem(widget.id)!.text);
    note = TextEditingController(text: widget.st.note(widget.id));
  }

  @override
  void dispose() {
    _deb?.cancel();
    _debN?.cancel();
    ed.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: widget.st,
      builder: (ctx, _) {
        final cur = widget.st.getItem(widget.id)!;
        final linked = widget.st
            .all
            .where((i) => widget.st.links(widget.id).contains(i.id))
            .toList();
        final latestNote = widget.st.note(widget.id);
        if (note.text != latestNote) {
          note.text = latestNote;
          note.selection =
              TextSelection.collapsed(offset: note.text.length);
        }
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: DefaultTabController(
            length: 4,
            child: Material(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(ico(cur.type)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('${lbl(cur.type)} • ${cur.id}',
                            style: Style.title,
                            overflow: TextOverflow.ellipsis)),
                    if (cur.status != ItemStatus.normal)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                            label: Text(cur.status.name),
                            visualDensity:
                                VisualDensity.compact),
                      ),
                    IconButton(
                        tooltip: 'Cerrar',
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            Navigator.of(ctx).pop()),
                  ]),
                ),
                const TabBar(tabs: [
                  Tab(icon: Icon(Icons.description), text: 'Contenido'),
                  Tab(icon: Icon(Icons.link), text: 'Relacionado'),
                  Tab(icon: Icon(Icons.info), text: 'Info'),
                  Tab(icon: Icon(Icons.timer), text: 'Tiempo'),
                ]),
                Expanded(
                  child: TabBarView(children: [
                    // Contenido
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(builder: (bCtx, cons) {
                        final base =
                            DefaultTextStyle.of(bCtx).style;
                        final fs = base.fontSize ?? 14.0;
                        final lh = fs * (base.height ?? 1.2);
                        final hAvail = cons.maxHeight.isFinite
                            ? cons.maxHeight
                            : MediaQuery.of(bCtx).size.height;
                        final cap = (hAvail * 0.9)
                            .clamp(lh * 3, double.infinity);
                        final maxL =
                            (cap / lh).floor().clamp(3, 2000);
                        return TextField(
                          controller: ed,
                          keyboardType:
                              TextInputType.multiline,
                          textInputAction:
                              TextInputAction.newline,
                          minLines: 3,
                          maxLines: maxL,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Escribe el contenido…'),
                          onChanged: (t) {
                            _deb?.cancel();
                            _deb = Timer(
                                const Duration(
                                    milliseconds: 250),
                                () =>
                                    widget.st.updateText(
                                        cur.id, t));
                          },
                        );
                      }),
                    ),
                    // Relacionado
                    linked.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.link_off,
                                    size: 48,
                                    color: Colors.grey),
                                Text('Sin relaciones',
                                    style: TextStyle(
                                        color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            primary: false,
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 8),
                            itemCount: linked.length,
                            itemBuilder: (ctx, i) {
                              final li = linked[i];
                              final ck = widget
                                  .st
                                  .links(widget.id)
                                  .contains(li.id);
                              return ItemCard(
                                it: li,
                                st: widget.st,
                                ex: false,
                                onT: () {},
                                onInfo: () => showInfoModal(
                                    c, li, widget.st),
                                cbL: true,
                                ck: ck,
                                onTapCb: () => widget.st
                                    .toggleLink(
                                        widget.id, li.id),
                              );
                            },
                          ),
                    // Info
                    ListView(
                      primary: false,
                      padding: const EdgeInsets.all(16),
                      children: [
                        info('📋 Tipo:',
                            cur.type == ItemType.idea
                                ? 'Ideas (B1)'
                                : 'Acciones (B2)'),
                        info('📅 Creado:', cur.createdAt.f),
                        info('🔄 Modificado:',
                            cur.modifiedAt.f),
                        info('📊 Estado:', cur.status.name),
                        info('🔢 Cambios:',
                            '${cur.statusChanges}'),
                        info('🔗 Relaciones:',
                            '${linked.length}'),
                      ],
                    ),
                    // Tiempo
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                          builder: (bCtx, cons) {
                        final base =
                            DefaultTextStyle.of(bCtx).style;
                        final fs = base.fontSize ?? 14.0;
                        final lh = fs * (base.height ?? 1.2);
                        final hAvail = cons.maxHeight.isFinite
                            ? cons.maxHeight
                            : MediaQuery.of(bCtx)
                                .size
                                .height;
                        final cap = (hAvail * 0.9)
                            .clamp(lh * 3, double.infinity);
                        final maxL =
                            (cap / lh).floor().clamp(3, 2000);
                        return TextField(
                          controller: note,
                          keyboardType:
                              TextInputType.multiline,
                          textInputAction:
                              TextInputAction.newline,
                          minLines: 3,
                          maxLines: maxL,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Notas de tiempo…'),
                          onChanged: (t) {
                            _debN?.cancel();
                            _debN = Timer(
                                const Duration(
                                    milliseconds: 250),
                                () =>
                                    widget.st.setNote(
                                        cur.id, t));
                          },
                        );
                      }),
                    ),
                  ]),
                )
              ]),
            ),
          ),
        );
      },
    );
  }
}

Widget info(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(l, style: Style.info)),
          Expanded(child: Text(v))
        ],
      ),
    );

/* ===== BLOQUES / PANTALLAS ===== */
class ItemTypeCfg {
  final String prefix, hint, label;
  final IconData icon;
  const ItemTypeCfg(
      {required this.prefix,
      required this.icon,
      required this.label,
      required this.hint});
}

typedef BuilderFn = Widget Function(BuildContext, AppState);

class Block {
  final String id;
  final IconData icon;
  final String label;
  final ItemType? type;
  final ItemTypeCfg? cfg;
  final Map<FilterKey, FilterMode> defaults;
  final BuilderFn? custom;
  const Block.item(
      {required this.id,
      required this.icon,
      required this.label,
      required this.type,
      required this.cfg,
      this.defaults = const {}})
      : custom = null;
  const Block.custom(
      {required this.id,
      required this.icon,
      required this.label,
      required this.custom})
      : type = null,
        cfg = null,
        defaults = const {};
}

final ideasCfg = ItemTypeCfg(
    prefix: 'B1',
    icon: Icons.lightbulb,
    label: 'Ideas',
    hint: 'Escribe tu idea...');
final actionsCfg = ItemTypeCfg(
    prefix: 'B2',
    icon: Icons.assignment,
    label: 'Acciones',
    hint: 'Describe la acción...');
final blocks = <Block>[
  Block.item(
      id: 'ideas',
      icon: ideasCfg.icon,
      label: ideasCfg.label,
      type: ItemType.idea,
      cfg: ideasCfg),
  Block.item(
      id: 'actions',
      icon: actionsCfg.icon,
      label: actionsCfg.label,
      type: ItemType.action,
      cfg: actionsCfg),
  Block.custom(
      id: 'links',
      icon: Icons.link,
      label: 'Enlaces',
      custom: (ctx, st) => LinksBlock(st: st)),
];

/* ===== PANTALLAS PRINCIPALES ===== */
class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override
  State<CaosBox> createState() => _CaosBoxState();
}
class _CaosBoxState extends State<CaosBox> {
  final st = AppState();
  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: st,
      builder: (_, __) => DefaultTabController(
        length: blocks.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox'),
            bottom: TabBar(tabs: [
              for (final b in blocks)
                Tab(icon: Icon(b.icon), text: b.label)
            ]),
          ),
          body: SafeArea(
            child: TabBarView(children: [
              for (final b in blocks)
                if (b.type != null)
                  GenericScreen(b: b, st: st)
                else
                  b.custom!(c, st)
            ]),
          ),
        ),
      ),
    );
  }
}

/* ===== SCREEN GENÉRICA ===== */
class GenericScreen extends StatefulWidget {
  final Block b;
  final AppState st;
  const GenericScreen({super.key, required this.b, required this.st});
  @override
  State<GenericScreen> createState() => _GenericScreenState();
}
class _GenericScreenState extends State<GenericScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _c;
  final _f = FilterSet();
  final _ex = <String>{};
  @override
  void initState() {
    super.initState();
    _c = TextEditingController();
    _f.setDefaults(widget.b.defaults);
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _r() => setState(() {});
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext ctx) {
    super.build(ctx);
    final t = widget.b.type!;
    final cfg = widget.b.cfg!;
    final filtered = FilterEngine.apply(widget.st.items(t), widget.st, _f);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        ComposerCard(
          icon: cfg.icon,
          hint: cfg.hint,
          c: _c,
          onAdd: () {
            widget.st.add(t, _c.text);
            _c.clear();
            _r();
          },
          onCancel: () {
            _c.clear();
            _r();
          },
        ),
        const SizedBox(height: 12),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            child: ChipsPanel(
                set: _f, onUpdate: _r, defaults: widget.b.defaults),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
            child: ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final it = filtered[i];
            final open = _ex.contains(it.id);
            return ItemCard(
              it: it,
              st: widget.st,
              ex: open,
              onT: () {
                if (open) {
                  _ex.remove(it.id);
                } else {
                  _ex.add(it.id);
                }
                _r();
              },
              onInfo: () => showInfoModal(ctx, it, widget.st),
            );
          },
        )),
      ]),
    );
  }
}

/* ===== BLOQUE ENLACES ===== */
class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({super.key, required this.st});
  @override
  State<LinksBlock> createState() => _LinksBlockState();
}
class _LinksBlockState extends State<LinksBlock>
    with AutomaticKeepAliveClientMixin {
  final l = FilterSet(), r = FilterSet();
  String? sel;
  @override
  void dispose() {
    l.dispose();
    r.dispose();
    super.dispose();
  }

  Widget panel(
          {required String t,
          required Widget chips,
          required Widget body}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(t,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
          Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(child: chips)),
          const SizedBox(height: 8),
          Expanded(child: body),
        ]),
      );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext c) {
    super.build(c);
    final st = widget.st;
    final li = FilterEngine.apply(st.all, st, l);
    final base = st.all.where((i) => i.id != sel).toList();
    final ri = FilterEngine.apply(base, st, r);

    final lb = ListView.builder(
      itemCount: li.length,
      itemBuilder: (_, i) {
        final it = li[i];
        return ItemCard(
          it: it,
          st: st,
          ex: false,
          onT: () {},
          onInfo: () => showInfoModal(c, it, st),
          cbR: true,
          ck: sel == it.id,
          onTapCb: () => setState(() => sel = sel == it.id ? null : it.id),
        );
      },
    );
    final rb = sel == null
        ? const Center(child: Text('Selecciona un elemento'))
        : ListView.builder(
            itemCount: ri.length,
            itemBuilder: (_, i) {
              final it = ri[i];
              final ck = st.links(sel!).contains(it.id);
              return ItemCard(
                it: it,
                st: st,
                ex: false,
                onT: () {},
                onInfo: () => showInfoModal(c, it, st),
                cbR: true,
                ck: ck,
                onTapCb: () => setState(
                    () => st.toggleLink(sel!, it.id)),
              );
            },
          );

    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Text('Conectar elementos', style: Style.title),
      ),
      Expanded(
        child: OrientationBuilder(builder: (ctx, o) => o ==
                Orientation.portrait
            ? Column(children: [
                Expanded(
                    child: panel(
                        t: 'Seleccionar:',
                        chips: ChipsPanel(set: l, onUpdate: () => setState(() {})),
                        body: lb)),
                const Divider(height: 1),
                Expanded(
                    child: panel(
                        t: 'Conectar con:',
                        chips: ChipsPanel(set: r, onUpdate: () => setState(() {})),
                        body: rb)),
              ])
            : Row(children: [
                Expanded(
                    child: panel(
                        t: 'Seleccionar:',
                        chips: ChipsPanel(set: l, onUpdate: () => setState(() {})),
                        body: lb)),
                const VerticalDivider(width: 1),
                Expanded(
                    child: panel(
                        t: 'Conectar con:',
                        chips: ChipsPanel(set: r, onUpdate: () => setState(() {})),
                        body: rb)),
              ])),
      ),
    ]);
  }
}
