import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'globals.dart';
import 'network.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  String user = '';
  String pass = '';
  String regCode = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkUserLogin();
  }

  Future<void> checkUserLogin() async {
    // Check if we have a token stored
    final prefs = await SharedPreferences.getInstance();
    String? storedToken = prefs.getString('token');
    if (storedToken == null) {
      // If we don't have a token, just let the user login
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      return;
    }
    // If we do, we need to check if its valid.
    http.Response resp = await http.get(
      Uri.parse('$apiUrl/api/v1/users/@me'),
      headers: {'Authorization': storedToken},
    );
    bool valid = false;
    if (resp.statusCode == 200) {
      Map<String, dynamic> data = json.decode(resp.body);
      if (data['status'] != 'success') {
        valid = false;
      } else {
        valid = true;
      }
    }
    if (!valid) {
      // If it's not valid, we need to tell the user their login has expired.
      if (!mounted) return;
      await prefs.remove('token');
      addToast('Login has expired. Please re-login');
      setState(() {
        loading = false;
      });
      return;
    }
    Map<String, dynamic> data = json.decode(resp.body)['data'];
    me = User.fromJson(data);
    token = storedToken;
    // If it's valid, then we go straight to the dashboard
    addToast('Successfully logged in!', error: false);
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/dash',
      (_) => false,
    );
  }

  String calculatePasswordHash(String password) {
    // Hashes the password client-side to prevent sending it as plaintext over the wire.
    List<int> passwordBytes = utf8.encode(password);
    Digest passwordHash = sha256.convert(passwordBytes);
    String passwordToSend = passwordHash.toString();
    return passwordToSend;
  }

  Future<String> register(String username, String password) async {
    String url = '$apiUrl/api/v1/auth/register';
    String passwordHash = calculatePasswordHash(password);
    bool proceed = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        // If the user was given a registration code (such as for a teacher account)
        // ask them to enter it here.
        return AlertDialog(
          title: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
            ),
            child: const Text(
              'Do you have a registration code?',
              textAlign: TextAlign.center,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'If you have been given a registration code, please enter it below.',
              ),
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Registration Code'),
                onChanged: (String value) => regCode = value,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ElevatedButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          // If they cancelled it, then don't proceed after closing.
                          proceed = false;
                          Navigator.of(context)
                              .popUntil(ModalRoute.withName('/'));
                        },
                      ),
                    ),
                    ElevatedButton(
                      child: const Text('Submit'),
                      onPressed: () {
                        proceed = true;
                        Navigator.of(context)
                            .popUntil(ModalRoute.withName('/'));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    // If the user cancelled:
    if (!proceed) return 'Cancelled by user';
    // POSTs to the server the user's desired details and waits for a response.
    Response response;
    try {
      response = await http.post(
        Uri.parse(url),
        body: {
          'username': username,
          'password': passwordHash,
          'registration_code': regCode
        },
      );
    } catch (e) {
      return 'Connection Error';
    }

    // If the response code isn't OK
    if (response.statusCode != 200) {
      if (response.statusCode == 500) {
        // Internal server errors mean that JSON was not returned, therefore we have to check as otherwise an error would occur trying to parse incorrect JSON.
        return 'Internal Server Error';
      }
      if (response.statusCode == 999) {
        return 'Connection Error';
      }
      return json.decode(response.body)['detail'];
    }
    var responseData = json.decode(response.body);

    // Combines the token and type together into a single string we can send with following requests.
    var token = responseData['access_token'];
    var tokenType = responseData['token_type'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', '$tokenType $token');
    return '$tokenType $token';
  }

  Future<String> login(String username, String password) async {
    String url = '$apiUrl/api/v1/auth/login';
    String passwordToSend = calculatePasswordHash(password);
    // POSTs to the server the user's details and waits for a response.
    Response response;
    try {
      response = await http.post(
        Uri.parse(url),
        body: {'username': username, 'password': passwordToSend},
      );
    } catch (e) {
      return 'Connection Error';
    }

    // If the response code isn't OK
    if (response.statusCode != 200) {
      if (response.statusCode == 500) {
        // Internal server errors mean that JSON was not returned, therefore we have to check as otherwise an error would occur trying to parse incorrect JSON.
        return 'Internal Server Error';
      }
      if (response.statusCode == 999) {
        return 'Connection Error';
      }
      return json.decode(response.body)['detail'];
    }
    var responseData = json.decode(response.body);

    // Combines the token and type together into a single string we can send with following requests.
    var token = responseData['access_token'];
    var tokenType = responseData['token_type'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', '$tokenType $token');
    return '$tokenType $token';
  }

  Future<void> validateRegistration() async {
    // Only register if the form is valid.
    if (!_formKey.currentState!.validate()) return;

    addToast('Registering as $user', error: false);
    String reason = await register(user, pass);
    ScaffoldMessenger.of(context).clearSnackBars();
    // All tokens start with "Bearer", anything else is an error message
    if (reason.startsWith('Bearer')) {
      token = reason;
      // This waits for the server to provide information on the user we logged in as.
      // This is done to get important information on the user such as their permissions.
      http.Response resp = await processNetworkRequest(
          NetworkOperation('$apiUrl/api/v1/users/@me', 'GET', (_) {}));
      if (!validateResponse(resp)) return;
      dynamic data = json.decode(resp.body)['data'];
      me = User.fromJson(data);
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dash',
        (_) => false,
      );
    } else {
      // If it fails, show this to the user.
      addToast('Registration failed: $reason');
    }
  }

  Future<void> validateLogin() async {
    // Only login if the form is valid.
    if (!_formKey.currentState!.validate()) return;

    addToast('Logging in as $user', error: false);
    String reason = await login(user, pass);
    ScaffoldMessenger.of(context).clearSnackBars();
    if (reason.startsWith('Bearer')) {
      token = reason;
      // Wait to recieve user data from the server.
      http.Response resp = await processNetworkRequest(
          NetworkOperation('$apiUrl/api/v1/users/@me', 'GET', (_) {}));
      if (!validateResponse(resp)) return;
      dynamic data = json.decode(resp.body)['data'];
      me = User.fromJson(data);
      Navigator.pushNamedAndRemoveUntil(context, '/dash', (_) => false);
    } else {
      addToast('Login failed: $reason');
    }
  }

  @override
  Widget build(BuildContext context) {
    currentScaffoldKey = loginScaffoldKey;
    return Scaffold(
      key: loginScaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          title: const Text('Login or Register'),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width / 1.25,
                  maxHeight: MediaQuery.of(context).size.height / 2,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).shadowColor,
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(1.5, 1.5),
                      blurRadius: 5.0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: loading
                      ? const [
                          // If we are checking if we are currently logged in.
                          Text('Verifying stored login'),
                          CircularProgressIndicator(
                            value: null,
                          ),
                        ]
                      : [
                          // If we need the user to login again
                          TextFormField(
                            decoration: const InputDecoration(
                              icon: Icon(Icons.person),
                              hintText: 'Username',
                              labelText: 'Username',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter a username';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              user = value;
                            },
                            onFieldSubmitted: (String _) async {
                              await validateLogin();
                            },
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              icon: Icon(Icons.key),
                              hintText: 'Password',
                              labelText: 'Password',
                            ),
                            // Ensure that the password is hidden
                            obscureText: true,
                            enableSuggestions: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter a password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters long.';
                              }
                              if (value.characters
                                  .where((String character) =>
                                      '1234567890'.contains(character))
                                  .isEmpty) {
                                return 'Password must contain a number.';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              pass = value;
                            },
                            onFieldSubmitted: (String _) async {
                              await validateLogin();
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await validateRegistration();
                                },
                                child: const Text('Register'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await validateLogin();
                                },
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
