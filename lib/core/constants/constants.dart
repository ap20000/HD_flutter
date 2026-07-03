class ApiConstants {
  // Use local network IP for physical device testing
  static const String baseUrl = 'http://192.168.1.81:5001';
  // static const String baseUrl = 'http://10.0.2.2:5001';
  // static const String baseUrl = 'https://mediumseagreen-locust-705726.hostingersite.com';
  static const String apiVersion = 'v1';

  // Auth Endpoints
  static const String login = '/api/$apiVersion/auth/login';
  static const String register = '/api/$apiVersion/auth/register';
  static const String verifyOtp = '/api/$apiVersion/auth/verify-otp';
  static const String getMe = '/api/$apiVersion/auth/me';
  static const String uploadAvatar = '/api/$apiVersion/users/avatar';

  // Patient Dashboard Endpoints
  static const String getDoctors = '/api/$apiVersion/users/doctors';
  static const String getArticles = '/api/$apiVersion/articles';
  static const String getRecords = '/api/$apiVersion/users/bmi';
  static const String getConsultations = '/api/$apiVersion/consultations';
  static const String stories = '/api/$apiVersion/stories';

  // Chatbot Endpoints
  static const String chatbotHistory = '/api/$apiVersion/chatbot/history';
  static const String chatbotChat = '/api/$apiVersion/chatbot/chat';
  static const String chatbotSave = '/api/$apiVersion/chatbot/save';

  // Doctor Dashboard Endpoints
  static const String getDoctorStats = '/api/$apiVersion/doctor/dashboard';
  static const String updateDoctorStatus = '/api/$apiVersion/doctor/status';
  static const String getDoctorHospitals = '/api/$apiVersion/doctor/hospitals';

  // Consultation Request Flow
  static const String requestConsultation =
      '/api/$apiVersion/consultations/request';
  static String respondToConsultation(String id) =>
      '/api/$apiVersion/consultations/$id/respond';
}
