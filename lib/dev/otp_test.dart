import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const OtpApp());
}

class OtpApp extends StatelessWidget {
  const OtpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OtpPage(phone: "+977 9800000000"),
    );
  }
}

class OtpPage extends StatefulWidget {
  final String phone;
  const OtpPage({super.key, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController shakeController;
  late Animation<double> offsetAnimation;

  bool loading = false;
  int resendSeconds = 60;

  @override
  void initState() {
    super.initState();

    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    offsetAnimation = Tween(
      begin: 0.0,
      end: 10.0,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(shakeController);

    startTimer();
  }

  void startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (resendSeconds == 0) return false;
      setState(() => resendSeconds--);
      return true;
    });
  }

  String get otp => controllers.map((e) => e.text).join();

  void handlePaste(String value) {
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        controllers[i].text = value[i];
      }
      FocusScope.of(context).unfocus();
      verify();
    }
  }

  void verify() async {
    HapticFeedback.mediumImpact();

    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          otp == "123456"
              ? "Verification successful"
              : "Invalid verification code",
        ),
      ),
    );
  }

  void onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),

      body: Center(
        child: AnimatedBuilder(
          animation: offsetAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(offsetAnimation.value, 0),
              child: child,
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),

            child: Column(
              children: [
                /// TOP ICON (medical feel)
                const Icon(
                  Icons.local_hospital_rounded,
                  size: 60,
                  color: Color(0xFF2563EB),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Verify your identity",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Enter the verification code sent to",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.phone,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 35),

                /// OTP BOXES (hospital soft style)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 46,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (value) {
                          if (value.length > 1) {
                            handlePaste(value);
                            return;
                          }
                          onChanged(value, index);
                        },
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                /// VERIFY BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Verify Code",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                /// RESEND TEXT (more medical tone)
                Center(
                  child: TextButton(
                    onPressed: resendSeconds == 0
                        ? () {
                            setState(() => resendSeconds = 60);
                            startTimer();
                            HapticFeedback.selectionClick();
                          }
                        : null,
                    child: Text(
                      resendSeconds == 0
                          ? "Resend verification code"
                          : "Resend available in $resendSeconds seconds",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
