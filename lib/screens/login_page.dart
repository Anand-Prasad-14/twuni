import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:twuni/screens/manager_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});


  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();


  final Box loginbox = Hive.box('loginBox');


  final List<String> roles = ['Manager', 'OfficeBoy'];
  String selectedRole = 'Manager';


  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<String> companyList = [];


  @override
  void initState() {
    _loadCompanies();
    super.initState();
  }


  void _loadCompanies() async {
    try {
      final companies = await _db.collection('company').get();
      setState(() {
        companyList.addAll(companies.docs.map((doc) => doc.id).toList());
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load companies: $e")));
    }
  }


  Future<void> _loginUser() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final company = _companyController.text.trim();
    final role = selectedRole;


    if (name.isEmpty || password.isEmpty || company.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields")));
      return;
    }


    final scName = _scEditor(name);
    final userRef = _db
        .collection(company)
        .doc(role.toLowerCase())
        .collection(scName)
        .doc('id');


    try {
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final storedPassword = userDoc.get('pass');
        if (storedPassword == password) {
          await _saveLoginInfo(scName, company, name);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Welcome $role!')));
          // Navigate to Manager Screen
          // Navigator.push(context, MaterialPageRoute(builder: (context) => role == 'Manager' ? ManagerActivity() : OfficeBoyActivity() ));
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ManagerPage(
                    companyId: company,
                    managerId: scName,
                    managerName: name,
                  )));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Invalid password")));
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("User not found")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }


  Future<void> _saveLoginInfo(
      String managerId, String company, String managerName) async {
    try {
      loginbox.put('managerId', managerId);
      loginbox.put('company', company);
      loginbox.put('managerName', managerName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Success to save login info: $managerName")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("failed to save login info: $managerName")),
      );
    }
  }


  String _scEditor(String name) {
    return name.toLowerCase().replaceAll(' ', '');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/registration_bg.jpg'),
                      fit: BoxFit.cover)),
              padding: const EdgeInsets.all(16.0)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0)),
                elevation: 10.0,
                color: Colors.grey,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 16.0,
                      ),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                            hintText: "Name",
                            hintStyle: const TextStyle(fontSize: 18),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none)),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: const TextStyle(fontSize: 18),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none)),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: InputDecoration(
                              hintText: "Select Role",
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none)),
                          items: roles.map((role) {
                            return DropdownMenuItem(
                                value: role, child: Text(role));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value!;
                            });
                          }),
                      const SizedBox(
                        height: 16,
                      ),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return companyList.where((company) => company
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()));
                        },
                        fieldViewBuilder: (context, textEditingController,
                            focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                                hintText: "Select Company",
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none)),
                          );
                        },
                        onSelected: (selection) {
                          _companyController.text = selection;
                        },
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      ElevatedButton(
                        onPressed: _loginUser,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 60),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0))),
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Image.asset(
              'assets/logoimg.png',
              width: 60,
              height: 60,
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 46.0),
              child: Text(
                'Developed by SK Robotics',
                style: TextStyle(
                    fontSize: 16, color: Color.fromARGB(255, 74, 74, 74)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



