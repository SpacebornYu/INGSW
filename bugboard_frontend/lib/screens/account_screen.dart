import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _auth = AuthService();
  String _email = "";
  String _role = "";
  bool _hidePass = true;

  @override
  void initState() { super.initState(); _load(); }

  void _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _email = p.getString('email') ?? "";
      _role = p.getString('role') ?? "";
    });
  }

  void _logout() {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C), title: const Text("Logout", style: TextStyle(color: Colors.white)),
      content: const Text("Sei sicuro di voler uscire? Per accedere dovrai nuovamente effettuare il login.", style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(child: const Text("Annulla"), onPressed: () => Navigator.pop(c)),
        TextButton(child: const Text("Esci", style: TextStyle(color: Colors.red)), onPressed: () {
          _auth.logout();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
        }),
      ],
    ));
  }

  void _create() {
    final ec = TextEditingController();
    final pc = TextEditingController();
    final rpc = TextEditingController();
    String nr = 'USER';
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setS) => Dialog( // Uso Dialog per controllare la larghezza
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1C1C1E),
          child: Padding(
            padding: const EdgeInsets.all(24.0), // Padding interno
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text("Nuovo Utente", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                const SizedBox(height: 30), // Spazio sotto titolo

                const Text("Email", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 8),
                _in(ec, "Inserisci email"),
                const SizedBox(height: 20), // Spazio tra i campi

                const Text("Password", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 8),
                _in(pc, "Password", obs: true),
                const SizedBox(height: 20),

                const Text("Ripeti Password", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 8),
                _in(rpc, "Conferma password", obs: true),
                const SizedBox(height: 30),

                // Toggle Ruolo
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    _rBtn("User", nr=='USER', ()=>setS(()=>nr='USER')),
                    _rBtn("Admin", nr=='ADMIN', ()=>setS(()=>nr='ADMIN'))
                  ]),
                ),
                const SizedBox(height: 30),

                // Bottoni Azione
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: const Text("Annulla", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      onPressed: () => Navigator.pop(c)
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E4F2F), // Verde scuro
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
                      ),
                      child: const Text("Crea", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        if(pc.text != rpc.text) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le password non coincidono")));
                           return;
                        }
                        String? errorMsg = await _auth.registerUser(ec.text, pc.text, nr);
                        Navigator.pop(c);
                        if(!mounted) return;
                        if (errorMsg == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Utente creato con successo!"), backgroundColor: Colors.green));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $errorMsg"), backgroundColor: Colors.red));
                        }
                      }
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _in(TextEditingController c, String h, {bool obs=false}) => TextField(
    controller: c, obscureText: obs,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: h, hintStyle: const TextStyle(color: Colors.grey),
      filled: true, fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
    )
  );
  Widget _rBtn(String l, bool a, VoidCallback t) => Expanded(
    child: GestureDetector(
      onTap: t,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: a ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10)
        ),
        child: Text(l, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
      )
    )
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Le tue credenziali", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            if(_role == 'ADMIN') IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: _create)
          ]),
        ),
        const SizedBox(height: 20),
        _field("Email", _email, false),
        const SizedBox(height: 20),
        _field("Password", "********", true),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900), onPressed: _logout, child: const Text("Logout", style: TextStyle(color: Colors.white)))),
        )
      ],
    );
  }

  Widget _field(String l, String v, bool p) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 8),
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)), child: Row(children: [
      Expanded(child: Text(p && _hidePass ? "••••••••" : (p ? "admin123" : v), style: const TextStyle(color: Colors.white))),
      if(p) GestureDetector(onTap: () => setState(() => _hidePass = !_hidePass), child: Icon(_hidePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey))
    ]))
  ]));
}