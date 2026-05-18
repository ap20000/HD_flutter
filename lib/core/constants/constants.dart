class ApiConstants {
  static const String baseUrl = 'https://mediumseagreen-locust-705726.hostingersite.com';
  static const String apiVersion = 'v1';
  
  // Auth Endpoints
  static const String login = '/api/$apiVersion/auth/login';
  static const String register = '/api/$apiVersion/auth/register';
  static const String verifyOtp = '/api/$apiVersion/auth/verify-otp';
  static const String getMe = '/api/$apiVersion/auth/me';

  // Patient Dashboard Endpoints
  static const String getDoctors = '/api/$apiVersion/users/doctors';
  static const String getArticles = '/api/$apiVersion/articles';
  static const String getRecords = '/api/$apiVersion/users/bmi';
  static const String getConsultations = '/api/$apiVersion/consultations';

  // Doctor Dashboard Endpoints
  static const String getDoctorStats = '/api/$apiVersion/doctor/dashboard';
  static const String updateDoctorStatus = '/api/$apiVersion/doctor/status';
  static const String getDoctorHospitals = '/api/$apiVersion/doctor/hospitals';
  
  // Consultation Request Flow
  static const String requestConsultation = '/api/$apiVersion/consultations/request';
  static String respondToConsultation(String id) => '/api/$apiVersion/consultations/$id/respond';
}
