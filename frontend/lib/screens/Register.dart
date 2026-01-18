import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(36, 36, 35, 100),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Register',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Sign In',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 40, top: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Music Review &',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        FaIcon(
                          FontAwesomeIcons.spotify,
                          color: Color(0xFF1DB954),
                          size: 40,
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                    Text(
                      'Discovery platform',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Email', style: TextStyle(color: Colors.white)),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'username@mail.com',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text('Password', style: TextStyle(color: Colors.white)),
                    SizedBox(height: 10),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '********************',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Confirm Password',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '********************',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Already have an account?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(30, 223, 99, 100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
