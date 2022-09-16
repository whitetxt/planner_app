// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import "package:http/http.dart" as http;
import 'package:crypto/crypto.dart';
import "package:flutter/material.dart";

import "globals.dart";
import 'network.dart';

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
                          // If they cancelled it, then don't proceed after closing.
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

    // If the user cancelled:
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
      if (response.statusCode == 999) {
        return "Connection Error";
      }
      return json.decode(response.body)["detail"];
    }
    var responseData = json.decode(response.body);

    // Combines the token and type together into a single string we can send with following requests.
    var token = responseData["data"]["access_token"];
    var tokenType = responseData["data"]["token_type"];
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
      if (response.statusCode == 999) {
        return "Connection Error";
      }
      return json.decode(response.body)["detail"];
    }
    var responseData = json.decode(response.body);

    // Combines the token and type together into a single string we can send with following requests.
    var token = responseData["data"]["access_token"];
    var tokenType = responseData["data"]["token_type"];
    return "$tokenType $token";
  }

  Future<void> validateRegistration() async {
    // Only register if the form is valid.
    if (_formKey.currentState!.validate()) {
      addNotif("Registering as $user", error: false);
      String reason = await register(user, pass);
      ScaffoldMessenger.of(context).clearSnackBars();
      if (reason.startsWith("Bearer")) {
        token = reason;
        // This waits for the server to provide information on the user we logged in as.
        // This is done to get important information on the user such as their permissions.
        http.Response resp = await processNetworkRequest(
            NetworkOperation("$apiUrl/api/v1/users/@me", "GET", (_) {}));
        if (!validateResponse(resp)) return;
        dynamic data = json.decode(resp.body)["data"];
        me = User(
          data["uid"],
          data["username"],
          DateTime.fromMillisecondsSinceEpoch(data["created_at"]),
          Permissions.values[data["permissions"]],
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/dash",
          (_) => false,
        );
      } else {
        // If it fails, show this to the user.
        addNotif("Registration failed: $reason");
      }
    }
    return;
  }

  Future<void> validateLogin() async {
    // Login doesn't need to be validated.
    addNotif("Logging in as $user", error: false);
    String reason = await login(user, pass);
    ScaffoldMessenger.of(context).clearSnackBars();
    if (reason.startsWith("Bearer")) {
      token = reason;
      // Wait to recieve user data from the server.
      http.Response resp = await processNetworkRequest(
          NetworkOperation("$apiUrl/api/v1/users/@me", "GET", (_) {}));
      if (!validateResponse(resp)) return;
      dynamic data = json.decode(resp.body)["data"];
      me = User(
        data["uid"],
        data["username"],
        DateTime.fromMillisecondsSinceEpoch(data["created_at"]),
        Permissions.values[data["permissions"]],
      );
      Navigator.pushNamedAndRemoveUntil(context, "/dash", (_) => false);
    } else {
      addNotif("Login failed: $reason");
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
                          return "Password must be at least 8 characters";
                        }
                        if (value.characters
                            .where((String character) =>
                                "1234567890".contains(character))
                            .isEmpty) {
                          return "Password must contain a number.";
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
                            validateRegistration();
                          },
                          child: const Text('Register'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
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
