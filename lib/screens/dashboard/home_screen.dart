import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskService taskService = TaskService();

  final TextEditingController titleController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

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
                  final task = TaskModel(
                    id: '',
                    userId: '',
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    isCompleted: false,
                  );

                  await taskService.addTask(task);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  titleController.clear();
                  descriptionController.clear();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),

      body: StreamBuilder<List<TaskModel>>(
        stream: taskService.getTasks(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;

          if (tasks.isEmpty) {
            return const Center(
              child: Text("No tasks yet 😴", style: TextStyle(fontSize: 20)),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,

            itemBuilder: (context, index) {
              final task = tasks[index];

              return Card(
                margin: const EdgeInsets.all(10),

                child: ListTile(
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

                  subtitle: Text(task.description),

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

      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
