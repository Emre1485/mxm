import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentsCard extends StatefulWidget {
  final List<String> studentIds;

  const StudentsCard({Key? key, required this.studentIds}) : super(key: key);

  @override
  _StudentsCardState createState() => _StudentsCardState();
}

class _StudentsCardState extends State<StudentsCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isExpanded = false;
  List<String> studentNames = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchStudentNames() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.studentIds.isEmpty) {
        studentNames = [];
      } else {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: widget.studentIds)
            .get();

        studentNames = snapshot.docs
            .map((doc) => (doc.data()['name'] ?? 'İsimsiz') as String)
            .toList();
      }
    } catch (e) {
      studentNames = [];
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void toggleExpansion() async {
    if (!_isExpanded) {
      await fetchStudentNames();
      _controller.forward();
    } else {
      _controller.reverse();
    }

    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.group, color: Colors.indigo),
            title: const Text(
              'Öğrenciler',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${widget.studentIds.length} öğrenci'),
            trailing: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
              child: const Icon(Icons.expand_more),
            ),
            onTap: toggleExpansion,
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : studentNames.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Öğrenci bulunamadı veya liste boş.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: studentNames.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(studentNames[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
