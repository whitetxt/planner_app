// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import "package:http/http.dart" as http;
import 'package:crypto/crypto.dart';
import "package:flutter/material.dart";

import "globals.dart";

class MainPageArgs {
  final String token;

  MainPageArgs(this.token);
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  String user = "";
  String pass = "";
  String regCode = "";

  String calculatePasswordHash(String password) {
    // Hashes the password client-side to prevent sending it as plaintext over the wire.
    List<int> passwordBytes = utf8.encode(password);
    Digest passwordHash = sha256.convert(passwordBytes);
    String passwordToSend = passwordHash.toString();
    return passwordToSend;
  }

  Future<String> register(String username, String password) async {
    String url = "$apiUrl/api/v1/auth/register";
    String passwordHash = calculatePasswordHash(password);
    bool proceed = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
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
              "Do you have a registration code?",
              textAlign: TextAlign.center,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                "If you have been given a registration code, please enter it below.",
              ),
              TextField(
                decoration:
                    const InputDecoration(labelText: "Registration Code"),
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
                        child: const Text("Cancel"),
                        onPressed: () {
                          proceed = false;
                          Navigator.of(context)
                              .popUntil(ModalRoute.withName("/"));
                        },
                      ),
                    ),
                    ElevatedButton(
                      child: const Text("Submit"),
                      onPressed: () {
                        proceed = true;
                        Navigator.of(context)
                            .popUntil(ModalRoute.withName("/"));
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

    if (!proceed) return "Cancelled by user";
    // POSTs to the server the user's desired details and waits for a response.
    final response = await http.post(
      Uri.parse(url),
      body: {
        "username": username,
        "password": passwordHash,
        "registration_code": regCode
      },
    );

    // If the response code isn't OK
    if (response.statusCode != 200) {
      if (response.statusCode == 500) {
        // Internal server errors mean that JSON was not returned, therefore we have to check as otherwise an error would occur trying to parse incorrect JSON.
        return "Internal Server Error";
      }
      return json.decode(response.body)["detail"];
    }
    var responseData = json.decode(response.body);

    // Combines the token and type together into a single string we can send with following requests.
    var token = responseData["access_token"];
    var tokenType = responseData["token_type"];
    return "$tokenType $token";
  }

  Future<String> login(String username, String password) async {
    String url = "$apiUrl/api/v1/auth/login";
    String passwordToSend = calculatePasswordHash(password);
    // POSTs to the server the user's details and waits for a response.
    final response = await http.post(
      Uri.parse(url),
      body: {"username": username, "password": passwordToSend},
    );

    // If the response code isn't OK
    if (response.statusCode != 200) {
      if (response.statusCode == 500) {
        // Internal server errors mean that JSON was not returned, therefore we have to check as otherwise an error would occur trying to parse incorrect JSON.
        return "Internal Server Error";
      }
      return json.decode(response.body)["detail"];
    }
    var responseData = json.decode(response.body);

    // Combines the token and type together into a single string we can send with following requests.
    var token = responseData["access_token"];
    var tokenType = responseData["token_type"];
    return "$tokenType $token";
  }

  Future<void> validateRegistration() async {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Registering as $user",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).cardColor,
          duration: const Duration(seconds: 5),
        ),
      );
      String reason = await register(user, pass);
      ScaffoldMessenger.of(context).clearSnackBars();
      if (reason.startsWith("Bearer")) {
        token = reason;
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/dash",
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Registration failed: $reason",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            backgroundColor: Theme.of(context).errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    return;
  }

  Future<void> validateLogin() async {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Logging in as $user",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.indigo.shade300,
          duration: const Duration(seconds: 5),
        ),
      );
      String reason = await login(user, pass);
      ScaffoldMessenger.of(context).clearSnackBars();
      if (reason.startsWith("Bearer")) {
        token = reason;
        Navigator.pushNamedAndRemoveUntil(context, "/dash", (_) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login failed: $reason",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          title: const Text("Login or Register"),
        ),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width / 1.5,
                  maxHeight: MediaQuery.of(context).size.height / 2,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).shadowColor,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person),
                        hintText: "Username",
                        labelText: "Username",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter a username";
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
                        hintText: "Password",
                        labelText: "Password",
                      ),
                      obscureText: true,
                      enableSuggestions: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter a password";
                        }
                        if (value.length < 8) {
                          return "Password must be more than 8 characters";
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
                            // Validate the form (returns true if all is ok)
                            validateRegistration();
                          },
                          child: const Text('Register'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // Validate the form (returns true if all is ok)
                            validateLogin();
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
