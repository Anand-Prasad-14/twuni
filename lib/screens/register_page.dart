import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:twuni/screens/login_page.dart';
import 'package:twuni/screens/manager_page.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});


  @override
  State<RegisterPage> createState() => _RegisterPageState();
}


class _RegisterPageState extends State<RegisterPage> {
  final Box loginBox = Hive.box('loginBox');


  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  String selectedRole = "Manager";


  final List<String> companyList = [];


  final FirebaseFirestore db = FirebaseFirestore.instance;


  @override
  void initState() {
    loadCompanies();
    _loadSavedLogin();
    super.initState();
  }


  Future<void> _loadSavedLogin() async {
    try {
      final String company = loginBox.get('company');
      final String managerId = loginBox.get('managerId');
      final String managerName = loginBox.get('managerName');


      if (company != null && managerName != null && managerId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ManagerPage(
                companyId: company,
                managerId: managerId,
                managerName: managerName,
              ),
            ),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome back, $managerName!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No login info found!')),
        );
      }
    } catch (e) {}
  }


  void loadCompanies() async {
    try {
      final querySnapshot = await db.collection('company').get();
      final companies = querySnapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        companyList.addAll(companies);
      });
    } catch (e) {
      print("Company load error: $companyList");
      showErrorToast("Failed to load companies: $e");
    }
  }


  void registerUser() async {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    final company = companyController.text.trim();


    if (email.isEmpty || name.isEmpty || password.isEmpty || company.isEmpty) {
      showErrorToast("Please fill all fields");
      return;
    }


    final documentId = name.replaceAll(" ", "").toLowerCase();
    final user = {"email": email, "name": name, "pass": password};


    final userCollection = selectedRole == "Manager"
        ? db.collection("tcs").doc("manager").collection(documentId)
        : db.collection("tcs").doc("officeboy").collection(documentId);


    try {
      await userCollection.doc("id").set(user);
      showSuccessToast("User registered successfully");


      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    } catch (e) {
      showErrorToast("Registration Failed: $e");
    }
  }


  void showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.green),
        )));
  }


  void showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.red),
        )));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
          Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/registration_bg.jpg'),
                    fit: BoxFit.cover)),
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0)),
                  elevation: 20.0,
                  color: Colors.grey,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        editTextField("Email", emailController),
                        const SizedBox(
                          height: 15,
                        ),
                        editTextField("Full Name", nameController),
                        const SizedBox(
                          height: 16.0,
                        ),
                        editTextField("Password", passwordController,
                            obscureText: true),
                        const SizedBox(
                          height: 16.0,
                        ),
                        DropdownButtonFormField(
                          value: selectedRole,
                          items: ["Manager", "OfficeBoy"]
                              .map((role) =>
                              DropdownMenuItem(value: role, child: Text(role)))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value!;
                            });
                          },
                          decoration: const InputDecoration(
                              labelText: "Select Role",
                              fillColor: Colors.white,
                              filled: true,
                              border:
                              OutlineInputBorder(borderSide: BorderSide.none)),
                        ),
                        const SizedBox(
                          height: 16.0,
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
                          onSelected: (selection) {
                            companyController.text = selection;
                          },
                          fieldViewBuilder: (context, textEditingController,
                              focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: "Select your company",
                                fillColor: Colors.white,
                                filled: true,
                                border:
                                OutlineInputBorder(borderSide: BorderSide.none),
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(12.0),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.76, // Dynamic width
                                  child: ListView.builder(
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return GestureDetector(
                                        onTap: () {
                                          onSelected(option);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10.0, horizontal: 15.0),
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 5.0),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                            BorderRadius.circular(8.0),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.business,
                                                  color: Colors.blue),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  option,
                                                  style:
                                                  const TextStyle(fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          height: 16.0,
                        ),
                        ElevatedButton(
                          onPressed: registerUser,
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0)),
                              textStyle: const TextStyle(fontSize: 18)),
                          child: const Text(
                            "REGISTER",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()));
                          },
                          child: const Text(
                            "Already have an account? Login here",
                            style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
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
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Developed by SK Robotics',
                style:
                TextStyle(fontSize: 16, color: Color.fromARGB(255, 74, 74, 74)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ]));
  }


  TextField editTextField(String hint, TextEditingController controller,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
          labelText: hint,
          fillColor: Colors.white,
          filled: true,
          border: const OutlineInputBorder(borderSide: BorderSide.none)),
    );
  }
}



