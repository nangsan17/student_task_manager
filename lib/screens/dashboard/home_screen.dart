import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskService taskService = TaskService();

  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

  final TextEditingController titleController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController deadlineController = TextEditingController();

  String selectedPriority = 'Low';

  void showAddTaskDialog() {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              const Text("Add Task"),

              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                icon: const Icon(Icons.close),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: titleController,

                decoration: const InputDecoration(labelText: "Task Title"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: descriptionController,

                decoration: const InputDecoration(labelText: "Description"),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField(
                value: selectedPriority,

                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),

                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),

                  DropdownMenuItem(value: 'High', child: Text('High')),
                ],

                onChanged: (value) {
                  setState(() {
                    selectedPriority = value!;
                  });
                },

                decoration: const InputDecoration(labelText: 'Priority'),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: deadlineController,
                readOnly: true,

                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  prefixIcon: Icon(Icons.calendar_today),
                ),

                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,

                    initialDate: DateTime.now(),

                    firstDate: DateTime(2024),

                    lastDate: DateTime(2030),
                  );

                  if (pickedDate != null) {
                    String formattedDate =
                        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

                    setState(() {
                      deadlineController.text = formattedDate;
                    });
                  }
                },
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Close"),
            ),

            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final currentUser = FirebaseAuth.instance.currentUser;

                  final task = TaskModel(
                    id: '',
                    userId: currentUser!.uid,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    priority: selectedPriority,
                    deadline: deadlineController.text.trim(),
                    isCompleted: false,
                  );

                  await taskService.addTask(task);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  titleController.clear();
                  descriptionController.clear();
                  deadlineController.clear();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Task Added 🚀")),
                  );
                }
              },

              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void showEditTaskDialog(TaskModel task) {
    titleController.text = task.title;
    descriptionController.text = task.description;

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Task"),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: titleController,

                decoration: const InputDecoration(labelText: "Task Title"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: descriptionController,

                decoration: const InputDecoration(labelText: "Description"),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                await taskService.editTask(
                  task.id,
                  titleController.text.trim(),
                  descriptionController.text.trim(),
                );

                titleController.clear();
                descriptionController.clear();

                if (context.mounted) {
                  Navigator.pop(context);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Task Updated 🚀")),
                );
              },

              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;

      case 'Medium':
        return Colors.orange;

      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),

        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,

                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },

            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),

            child: TextField(
              controller: searchController,

              decoration: InputDecoration(
                hintText: 'Search tasks...',

                prefixIcon: const Icon(Icons.search),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: taskService.getTasks(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!
                    .where(
                      (task) => task.title.toLowerCase().contains(searchQuery),
                    )
                    .toList();

                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tasks found 😴",

                      style: TextStyle(fontSize: 20),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,

                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    return Card(
                      margin: const EdgeInsets.all(10),

                      child: ListTile(
                        onTap: () {
                          showEditTaskDialog(task);
                        },

                        leading: Checkbox(
                          value: task.isCompleted,

                          onChanged: (value) async {
                            await taskService.updateTaskStatus(
                              task.id,
                              task.isCompleted,
                            );
                          },
                        ),

                        title: Text(task.title),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(task.description),

                            const SizedBox(height: 5),

                            Text(
                              "Priority: ${task.priority}",

                              style: TextStyle(
                                color: getPriorityColor(task.priority),

                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text("Deadline: ${task.deadline}"),
                          ],
                        ),

                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),

                          onPressed: () async {
                            await taskService.deleteTask(task.id);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
