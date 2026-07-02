import 'package:equatable/equatable.dart';

abstract class ConsultationEvent extends Equatable {
  const ConsultationEvent();

  @override
  List<Object?> get props => [];
}

class JoinConsultation extends ConsultationEvent {
  final String consultationId;
  const JoinConsultation(this.consultationId);

  @override
  List<Object?> get props => [consultationId];
}

class SendChatMessage extends ConsultationEvent {
  final String text;
  final String senderId;
  const SendChatMessage(this.text, this.senderId);

  @override
  List<Object?> get props => [text, senderId];
}

class MessageReceived extends ConsultationEvent {
  final Map<String, dynamic> message;
  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class StartCall extends ConsultationEvent {
  final bool isVideo;
  const StartCall({required this.isVideo});

  @override
  List<Object?> get props => [isVideo];
}

class HandleCallSignal extends ConsultationEvent {
  final Map<String, dynamic> signal;
  const HandleCallSignal(this.signal);

  @override
  List<Object?> get props => [signal];
}

class ToggleMute extends ConsultationEvent {}

class ToggleCamera extends ConsultationEvent {}

class SwitchCamera extends ConsultationEvent {}

class EndConsultationCall extends ConsultationEvent {}

class AcceptCall extends ConsultationEvent {}

class RejectCall extends ConsultationEvent {}
