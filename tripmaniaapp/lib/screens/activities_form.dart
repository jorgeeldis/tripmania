import 'package:flutter/material.dart';
import 'package:tripmaniaapp/main.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as dtp;

void main() {
  runApp(const ActivitiesFormScreen());
}

class ActivitiesFormScreen extends StatefulWidget {
  const ActivitiesFormScreen({super.key});
  @override
  _ActivitiesFormScreenState createState() => _ActivitiesFormScreenState();
}

class _ActivitiesFormScreenState extends State<ActivitiesFormScreen> {
  DateTime? _selectedDate;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activities Form',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Activities Form'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: ListView(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Activity Name',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        dtp.DatePicker.showDatePicker(
                          context,
                          showTitleActions: true,
                          minTime: DateTime(2018, 3, 5),
                          maxTime: DateTime(2029, 12, 31),
                          theme: dtp.DatePickerTheme(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            headerColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            itemStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            doneStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 18,
                            ),
                          ),
                          onChanged: (date) {
                            print('change $date');
                          },
                          onConfirm: (date) {
                            print('confirm $date');
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          currentTime: DateTime.now(),
                          locale: dtp.LocaleType.en,
                        );
                      },
                      child: _selectedDate == null
                          ? const Text('Select Date')
                          : Text(
                              'Selected Date: ${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Estimated Cost',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Maps Link'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Images'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      // Handle form submission
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
