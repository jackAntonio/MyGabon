import 'package:flutter/material.dart';

import '../widgets/custom_textfield.dart';
import '../utils/validators.dart';
import '../widgets/primary_button.dart';

/// Screen with a form for posting an announcement or service.
class PostAnnouncementScreen extends StatefulWidget {
  const PostAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends State<PostAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  String? _category;
  String? _price;
  String? _location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Announcement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Title',
                validator: Validators.validateNotEmpty,
                onSaved: (v) => _title = v,
              ),
              CustomTextField(
                label: 'Description',
                validator: Validators.validateNotEmpty,
                onSaved: (v) => _description = v,
                keyboardType: TextInputType.multiline,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Repair', child: Text('Repair')),
                  DropdownMenuItem(value: 'IT Services', child: Text('IT Services')),
                  DropdownMenuItem(value: 'Cleaning', child: Text('Cleaning')),
                  DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                  DropdownMenuItem(value: 'Marketplace', child: Text('Marketplace')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => _category = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              CustomTextField(
                label: 'Price',
                keyboardType: TextInputType.number,
                onSaved: (v) => _price = v,
              ),
              CustomTextField(
                label: 'Location',
                onSaved: (v) => _location = v,
              ),
              const SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Center(child: Text('Image upload placeholder')),
              ),
              const SizedBox(height: 24),
              // use reusable primary button
              PrimaryButton(
                label: 'Submit',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      // TODO: handle submission logic (e.g. send to backend)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Posted: $_title, desc: $_description, category: $_category, price: $_price, location: $_location')),
      );
      _formKey.currentState?.reset();
    }
  }
}
