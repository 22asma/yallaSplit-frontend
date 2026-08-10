class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'http://localhost:3000/v1'; 
  // 10.0.2.2 = localhost de la machine hôte vue depuis l'émulateur Android.
  // Sur iOS simulator tu peux utiliser localhost directement.
  // À déplacer dans env.dart selon dev/prod plus tard.

  // --- Auth ---
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String sendVerificationEmail = '/auth/send-verification-email';
  static const String verifyEmail = '/auth/verify-email';

  // --- User ---
  static const String me = '/users/me';
  static const String deviceToken = '/notifications/device-token';

  // --- Addition ---
  static const String additions = '/additions';
  static String additionById(String id) => '/additions/$id';
  static const String scanRecu = '/additions/scan-recu';
  static String lienPaiement(String additionId) => '/additions/$additionId/lien-paiement';
  static String participants(String additionId) => '/additions/$additionId/participants';

  static String lienPaiementPublic(String token) => '/lien-paiement/$token';
static String rejoindre(String token) => '/lien-paiement/$token/participants';
static String assignerArticle(String token, String participantId) =>
    '/lien-paiement/$token/participants/$participantId/articles';
static String modifierAssignation(String token, String participantId, String articleParticipantId) =>
    '/lien-paiement/$token/participants/$participantId/articles/$articleParticipantId';
static String supprimerAssignation(String token, String participantId, String articleParticipantId) =>
    '/lien-paiement/$token/participants/$participantId/articles/$articleParticipantId';
static String calculerMontant(String token, String participantId) =>
    '/lien-paiement/$token/participants/$participantId/montant';
static String payer(String token, String participantId) =>
    '/lien-paiement/$token/participants/$participantId/payer';
static String confirmerPaiement(String token, String participantId) =>
    '/lien-paiement/$token/participants/$participantId/confirmer-paiement';

    static String updateAddition(String id) => '/additions/$id';
static String deleteAddition(String id) => '/additions/$id';
static String addArticleToAddition(String additionId) => '/additions/$additionId/articles';
static String updateArticleOfAddition(String additionId, String articleId) =>
    '/additions/$additionId/articles/$articleId';
static String deleteArticleOfAddition(String additionId, String articleId) =>
    '/additions/$additionId/articles/$articleId';

    static String getParticipantPublic(String token, String participantId) =>
    '/lien-paiement/$token/participants/$participantId';

    static String choisirTaxe(String token, String participantId) =>
    '/lien-paiement/$token/participants/$participantId/taxe';
static String retirerTaxe(String token, String participantId) =>
    '/lien-paiement/$token/participants/$participantId/taxe';
}