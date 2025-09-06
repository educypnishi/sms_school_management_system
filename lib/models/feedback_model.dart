class FeedbackModel {
  final String id;
  final String applicationId;
  final String partnerId;
  final String text;
  final String date;

  FeedbackModel({
    required this.id,
    required this.applicationId,
    required this.partnerId,
    required this.text,
    required this.date,
  });

  // Create a FeedbackModel from a map
  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      applicationId: map['applicationId'] ?? '',
      partnerId: map['partnerId'] ?? '',
      text: map['text'] ?? '',
      date: map['date'] ?? '',
    );
  }

  // Convert FeedbackModel to a map
  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'partnerId': partnerId,
      'text': text,
      'date': date,
    };
  }
}
