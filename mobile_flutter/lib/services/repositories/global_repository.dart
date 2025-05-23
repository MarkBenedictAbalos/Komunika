abstract class GlobalRepository {
  Future<void> sendTextToSpeech(String text, String title, bool save);
  Future<void> startLiveTranscription();
}
