import 'dart:io';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


class ManagerPage extends StatefulWidget {
  final String companyId;
  final String managerId;
  final String managerName;


  const ManagerPage({
    super.key,
    required this.companyId,
    required this.managerId,
    required this.managerName,
  });


  @override
  State<ManagerPage> createState() => _ManagerPageState();
}


class _ManagerPageState extends State<ManagerPage> {
  final Box loginBox = Hive.box('loginBox');


  late TextEditingController taskController;
  late FirebaseFirestore firestore;
  late stt.SpeechToText _speechToText;
  bool isListening = false;
  List<String> officeBoys = ['All'];
  String selectedOfficeBoy = 'All';
  bool isAssigningTask = false;


  @override
  void initState() {
    super.initState();
    taskController = TextEditingController();
    firestore = FirebaseFirestore.instance;
    _speechToText = stt.SpeechToText();
    fetchOfficeBoys();
  }


  Future<void> fetchOfficeBoys() async {
    try {
      DocumentSnapshot snapshot = await firestore
          .collection(widget.companyId)
          .doc("manager")
          .collection(widget.managerId)
          .doc("reportingofficeboys")
          .get();


      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          officeBoys = ['All'];
          data.forEach((key, value) {
            if (value == true) {
              officeBoys.add(key);
            }
          });
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching office boys: ");
    }
  }


  Future<void> assignTask() async {
    if (taskController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Task description cannot be empty.");
      return;
    }


    setState(() {
      isAssigningTask = true;
    });


    String taskDescription = taskController.text.trim();
    String currentDateTime = DateTime.now().toString();
    String taskId = const Uuid().v4();


    Map<String, dynamic> taskData = {
      "taskId": taskId,
      "desc": taskDescription,
      "managerId": widget.managerId,
      "status": "pending",
      "assignedTo": selectedOfficeBoy,
      "assignedTime": currentDateTime
    };


    await firestore
        .collection(widget.companyId)
        .doc("manager")
        .collection(widget.managerId)
        .doc("tasks")
        .set({"$selectedOfficeBoy $currentDateTime": taskData},
        SetOptions(merge: true));


    try {
      if (selectedOfficeBoy == 'All') {
        for (String officeBoy in officeBoys) {
          if (officeBoy != 'All') {
            await firestore
                .collection(widget.companyId)
                .doc("officeboy")
                .collection(officeBoy)
                .doc("task")
                .set({"${widget.managerId} $currentDateTime": taskData},
                SetOptions(merge: true));
          }
          Fluttertoast.showToast(msg: "Task assigned to $officeBoy");
        }
      } else {
        await firestore
            .collection(widget.companyId)
            .doc("officeboy")
            .collection(selectedOfficeBoy)
            .doc("task")
            .set({"${widget.managerId} $currentDateTime": taskData},
            SetOptions(merge: true));


        Fluttertoast.showToast(msg: "Task assigned to All");
      }


      listenTaskAcceptance(widget.companyId, widget.managerId, taskId);


      taskController.clear();
      Fluttertoast.showToast(msg: "Task assigned successfully.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error assigning task: $e");
    } finally {
      setState(() {
        isAssigningTask = false;
      });
    }
  }


  Future<void> listenTaskAcceptance(
      String companyId, String managerId, String taskId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;


    firestore
        .collection(companyId)
        .doc("manager")
        .collection(managerId)
        .doc("tasks")
        .snapshots()
        .listen((documentSnapshot) {
      if (documentSnapshot.exists) {
        // Extract the tasks from the document
        Map<String, dynamic>? tasks = documentSnapshot.data();


        if (tasks != null) {
          bool taskFound = false;
          // Search for the specific task by taskId
          for (var taskEntry in tasks.entries) {
            Map<String, dynamic> task = taskEntry.value as Map<String, dynamic>;


            if (task['taskId'] == taskId) {
              taskFound = true;
              String status = task['status'] ?? 'Unknown';
              if (status.toLowerCase() == "accepted") {
                String assignedTask = task['assignedTo'] ?? 'Unknown';
                Fluttertoast.showToast(msg: "Task accepted by '$assignedTask'");
              } else {
                Fluttertoast.showToast(msg: "Task '$taskId' not yet accepted.");
              }
            }
          }


          if (!taskFound) {
            Fluttertoast.showToast(msg: "Task '$taskId' not found.");
          }
        } else {
          Fluttertoast.showToast(msg: "No tasks available.");
        }
      } else {
        Fluttertoast.showToast(msg: "No tasks found");
      }
    });
  }


  // Future<void> checkTaskAcceptance(
  //     String selectedOfficeBoyName, String currentDateTime) async {
  //   try {
  //     // Fetch the document from Firestore
  //     DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
  //         .collection(widget.companyId)
  //         .doc("manager")
  //         .collection(widget.managerId)
  //         .doc("tasks")
  //         .get();


  //     // Check if the document exists and has data
  //     if (documentSnapshot.exists && documentSnapshot.data() != null) {
  //       Map<String, dynamic>? data =
  //           documentSnapshot.data() as Map<String, dynamic>?;


  //       // Iterate through the document's data
  //       data?.forEach((key, value) {
  //         if (key == "$selectedOfficeBoyName $currentDateTime") {
  //           // Cast the value to a map and check the status
  //           Map<String, dynamic>? checkingAcceptedMap =
  //               value as Map<String, dynamic>?;


  //           checkingAcceptedMap?.forEach((key, value) {
  //             if (key == "status" && value != "pending") {
  //               Fluttertoast.showToast(msg: "Task accepted");
  //             } else {
  //               Fluttertoast.showToast(msg: "Task not accepeted");
  //               // Infinite loop replaced with log for debugging; handle gracefully in production
  //               debugPrint("Task status is still pending. Waiting...");
  //             }
  //           });
  //         }
  //       });
  //     } else {
  //       debugPrint("Document not found or no data available.");
  //     }
  //   } catch (e) {
  //     debugPrint("Error fetching task acceptance: $e");
  //   }
  // }


  // Fetch tasks from Firestore and export them to a CSV file
  // Export tasks to Excel file
  Future<void> exportTasksToExcel(BuildContext context) async {
    FirebaseFirestore db = FirebaseFirestore.instance;


    try {
      // Fetch tasks from Firestore
      DocumentSnapshot documentSnapshot = await db
          .collection(widget.companyId)
          .doc("manager")
          .collection(widget.managerId)
          .doc("tasks")
          .get();


      if (documentSnapshot.exists) {
        // Prepare data for Excel
        var excelFile = excel.Excel.createExcel();
        excel.Sheet sheet = excelFile['Sheet1'];


        // Add headers with CellValue (StringCellValue)
        sheet.appendRow([
          excel.TextCellValue("Task Description"),
          excel.TextCellValue("Assigned To"),
          excel.TextCellValue("Status"),
          excel.TextCellValue("Accepted Time")
        ]);


        // Iterate through the tasks and add them to the Excel data
        Map<String, dynamic> tasks =
        documentSnapshot.data() as Map<String, dynamic>;
        tasks.forEach((taskKey, taskData) {
          Map<String, dynamic> taskMap = taskData as Map<String, dynamic>;
          String taskDescription = taskMap["desc"] ?? "No Description";
          String assignedTo = taskMap["assignedTo"] ?? "Unknown";
          String status = taskMap["status"] ?? "Unknown";
          String acceptedTime = taskMap["assignedTime"] ?? "Not Accepted";


          // Add the task data as a row in the Excel sheet with CellValue
          sheet.appendRow([
            excel.TextCellValue(taskDescription),
            excel.TextCellValue(assignedTo),
            excel.TextCellValue(status),
            excel.TextCellValue(acceptedTime),
          ]);
        });


        // Get the directory to store the Excel file (Download directory)
        Directory? directory;
        if (Platform.isAndroid) {
          // Check if the app has storage permission and request it if necessary
          PermissionStatus permission = await Permission.storage.request();
          if (!permission.isGranted) {
            Fluttertoast.showToast(msg: "Storage permission not granted.");
            return;
          }


          // Get the 'Download' directory
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            await directory.create(
                recursive: true); // Create the folder if it doesn't exist
          }
        } else {
          // For iOS or other platforms, use a safe directory (Documents directory)
          directory = await getApplicationDocumentsDirectory();
        }


        // Save the Excel file to the directory
        File file = File('${directory.path}/Tasks.xlsx');
        List<int>? bytes = await excelFile.encode();
        if (bytes != null) {
          await file.writeAsBytes(bytes);
          // Notify the user of success
          Fluttertoast.showToast(
              msg: "Excel File Exported Successfully at ${file.path}");
        } else {
          Fluttertoast.showToast(msg: "Error: Failed to generate Excel file.");
        }
      } else {
        Fluttertoast.showToast(msg: "No task data found.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error Exporting Tasks: ${e.toString()}");
      print("Error Exporting Tasks: $e");
    }
  }


  Future<void> startListening() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) => print("Speech status: $status"),
        onError: (errorNotification) =>
            print("Speech error: $errorNotification"),
      );


      if (available) {
        setState(() {
          isListening = true;
        });


        _speechToText.listen(
          onResult: (result) {
            setState(() {
              taskController.text = result.recognizedWords;
            });
          },
        );
      } else {
        Fluttertoast.showToast(msg: "Speech recognition not available.");
      }
    } catch (e) {
      print("Speech-to-Text Initialization Error: $e");
      Fluttertoast.showToast(msg: "Failed to initialize Speech-to-Text.");
    }
  }


  void stopListening() {
    setState(() {
      isListening = false;
    });
    _speechToText.stop();
  }


  void handleNavigation(int index) {
    switch (index) {
      case 0: // Input mic
        isListening ? stopListening() : startListening();
        break;
      case 1: // Export
        exportTasksToExcel(context);
        break;
      case 2: // Logout
        signOut();
        break;
    }
  }


  Future<void> signOut() async {
    try {
      // Clear the login box (Assuming loginBox is properly initialized elsewhere)
      await loginBox.clear();


      // Update the isLive status in Firestore
      final isLiveMap = {"isLive": false};


      await firestore
          .collection("company")
          .doc(widget.companyId)
          .collection("manager")
          .doc(widget.managerId)
          .update(isLiveMap);


      debugPrint("Manager is set to offline.");


      // Navigate to the login page and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);


      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully.')),
      );
    } catch (e) {
      // Handle errors gracefully
      debugPrint("Error during sign-out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during sign-out: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 34,
                ),
                Center(
                  child: Text(
                    "Assign Task",
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                DropdownButton<String>(
                    value: selectedOfficeBoy,
                    isExpanded: true,
                    items: officeBoys
                        .map((officeBoy) => DropdownMenuItem(
                        value: officeBoy, child: Text(officeBoy)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedOfficeBoy = value!;
                      });
                    }),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: taskController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                      labelText: "Task Description",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder()),
                ),
                const SizedBox(
                  height: 10,
                ),
                Center(
                  child: SizedBox(
                    width: 350,
                    child: ElevatedButton(
                      onPressed: assignTask,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16)),
                      child: isAssigningTask
                          ? const CircularProgressIndicator()
                          : const Text(
                        "Assign Task",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: Image.asset(
              'assets/logoimg.png',
              height: 80,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Spacer()
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Colors.grey, width: 2), // Add a top border
                bottom: BorderSide(
                    color: Colors.grey, width: 2), // Add a bottom border
                left: BorderSide(
                    color: Colors.grey,
                    width: 2), // Optional: Add a left border
                right: BorderSide(
                    color: Colors.grey,
                    width: 2), // Optional: Add a right border
              ),
            ),
            child: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'voice'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.download), label: 'export'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.logout), label: 'logout')
              ],
              onTap: handleNavigation,
            ),
          ),
        ),
      ),
    );
  }
}



