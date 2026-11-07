import 'package:flutter/material.dart';

import '../services/token_store.dart';

/// App language. Default is Arabic (RTL). French is kept as a toggle for staff.
class LocaleController extends ChangeNotifier {
  LocaleController._({TokenStore? store})
      : _store = store ?? FallbackTokenStore(const SecureTokenStore());

  static final LocaleController instance = LocaleController._();

  @visibleForTesting
  factory LocaleController.forTest(TokenStore store) {
    return LocaleController._(store: store);
  }

  static const _localeKey = 'app_locale';
  static const _chosenKey = 'app_locale_chosen';
  final TokenStore _store;

  Locale _locale = const Locale('ar');
  bool _chosen = false;
  Locale get locale => _locale;
  bool get hasChosenLanguage => _chosen;
  bool get isArabic => _locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;
  AppStrings get s => AppStrings(isArabic);

  Future<void> load() async {
    try {
      final saved = await _store.read(_localeKey);
      final chosen = await _store.read(_chosenKey);
      if (saved == 'fr' || saved == 'ar') {
        _locale = Locale(saved!);
        _chosen = true;
      } else if (chosen == '1') {
        _chosen = true;
      }
    } catch (_) {
      // Keep the default Arabic locale if secure storage is unavailable.
    }
  }

  Future<void> setArabic(bool arabic) async {
    _locale = Locale(arabic ? 'ar' : 'fr');
    _chosen = true;
    notifyListeners();
    try {
      await _store.write(_localeKey, _locale.languageCode);
      await _store.write(_chosenKey, '1');
    } catch (_) {}
  }
}

extension L10nX on BuildContext {
  AppStrings get s => LocaleController.instance.s;
}

class AppStrings {
  const AppStrings(this.ar);
  final bool ar;

  String _t(String arabic, String french) => ar ? arabic : french;

  String get welcome => _t('مرحباً !', 'Bienvenue !');
  String get loginSubtitle =>
      _t('سجّل الدخول إلى حسابك', 'Connectez-vous à votre compte');
  String get identifier =>
      _t('البريد أو الاسم أو المعرّف', 'Email, nom ou identifiant');
  String get password => _t('كلمة المرور', 'Mot de passe');
  String get login => _t('تسجيل الدخول', 'Se connecter');
  String get forgotPassword => _t('نسيت كلمة المرور؟', 'Mot de passe oublié ?');
  String get enterIdentifier => _t('أدخل المعرّف', 'Entrez votre identifiant');
  String get passwordTooShort =>
      _t('كلمة المرور قصيرة جداً (6 أحرف على الأقل)', 'Mot de passe trop court (6 caractères min)');
  String get invalidCredentials =>
      _t('المعرّف أو كلمة المرور غير صحيحة', 'Identifiant ou mot de passe incorrect');
  String get tooManyAttempts =>
      _t('محاولات كثيرة. أعد المحاولة بعد دقائق.', 'Trop de tentatives. Réessayez dans quelques minutes.');
  String get networkError =>
      _t('خطأ في الاتصال. تحقق من الشبكة.', 'Erreur de connexion. Vérifiez votre réseau.');
  String get invalidRole => _t('دور غير صالح', 'Rôle non valide');

  String get forgotTitle => _t('نسيت كلمة المرور', 'Mot de passe oublié');
  String get forgotHint => _t(
        'سيتم إرسال طلب إلى المكتب. سنتصل بك ونرسل كلمة مرور جديدة.',
        'Une réclamation sera envoyée au bureau. Nous vous contacterons et vous enverrons un nouveau mot de passe.',
      );
  String get email => _t('البريد الإلكتروني', 'E-mail');
  String get phone => _t('الهاتف', 'Téléphone');
  String get optionalMessage => _t('رسالة (اختياري)', 'Message (optionnel)');
  String get sendReclamation => _t('إرسال الطلب', 'Envoyer la réclamation');
  String get reclamationSent => _t('تم إرسال الطلب', 'Réclamation envoyée');
  String get bureauWillContact => _t(
        'سيتصل بك المكتب ويرسل كلمة مرور جديدة.',
        'Le bureau vous contactera et vous enverra un nouveau mot de passe.',
      );
  String get backToLogin => _t('العودة لتسجيل الدخول', 'Retour à la connexion');
  String get enterEmail => _t('أدخل بريدك الإلكتروني', 'Entrez votre e-mail');
  String get enterValidEmail => _t('أدخل بريداً صالحاً', 'Entrez un e-mail valide');
  String get enterPhone => _t('أدخل رقم الهاتف', 'Entrez votre numéro de téléphone');
  String get invalidPhone => _t('رقم هاتف غير صالح', 'Numéro de téléphone invalide');
  String get cannotSendReclamation => _t(
        'تعذر إرسال الطلب. اتصل بالمكتب.',
        'Impossible d’envoyer la réclamation. Appelez le bureau.',
      );
  String bureauLine(String phone) =>
      _t('المكتب : $phone', 'Bureau : $phone');

  String get retry => _t('إعادة المحاولة', 'Réessayer');
  String get profile => _t('الملف الشخصي', 'Profil');
  String get settings => _t('الإعدادات', 'Paramètres');
  String get account => _t('الحساب', 'Compte');
  String get preferences => _t('التفضيلات', 'Préférences');
  String get support => _t('الدعم', 'Assistance');
  String get viewProfile => _t('عرض الملف الشخصي', 'Voir le profil');
  String get callOffice => _t('اتصال بالمكتب', 'Appeler le bureau');
  String get emailOffice => _t('بريد المكتب', 'E-mail du bureau');
  String appVersion(String version) => _t('الإصدار $version', 'Version $version');
  String get logout => _t('تسجيل الخروج', 'Déconnexion');
  String get changePassword => _t('تغيير كلمة المرور', 'Changer le mot de passe');
  String get mustChangePasswordTitle =>
      _t('يجب تغيير كلمة المرور', 'Changement de mot de passe requis');
  String get signInAgain => _t(
        'سجّل الدخول من جديد بكلمة المرور الجديدة',
        'Reconnectez-vous avec le nouveau mot de passe',
      );
  String get contactAfterPassword => _t(
        'أضف رقم هاتفك وبريدك. يمكنك ترك الحقل فارغاً.',
        'Ajoutez votre téléphone et votre e-mail. Un champ vide reste inchangé.',
      );
  String get currentPassword => _t('كلمة المرور الحالية', 'Mot de passe actuel');
  String get newPassword => _t('كلمة المرور الجديدة', 'Nouveau mot de passe');
  String get confirmNewPassword =>
      _t('تأكيد كلمة المرور الجديدة', 'Confirmer le nouveau mot de passe');
  String get passwordsDoNotMatch =>
      _t('كلمتا المرور غير متطابقتين', 'Les mots de passe ne correspondent pas');
  String get passwordSameAsCurrent => _t(
        'كلمة المرور الجديدة يجب أن تختلف عن الحالية',
        'Le nouveau mot de passe doit être différent de l’actuel',
      );
  String get changePasswordHint => _t(
        'اختياري. اتركه فارغاً إذا كنت لا تريد تغيير كلمة المرور الآن.',
        'Optionnel. Laissez vide si vous ne voulez pas changer le mot de passe maintenant.',
      );
  String get update => _t('تحديث', 'Mettre à jour');
  String get passwordUpdated =>
      _t('تم تحديث كلمة المرور بنجاح', 'Mot de passe mis à jour avec succès !');
  String get passwordUpdateFailed =>
      _t('تعذر تحديث كلمة المرور.', 'Impossible de mettre à jour le mot de passe.');
  String get cannotLoadProfile =>
      _t('تعذر تحميل الملف الشخصي.', 'Impossible de charger le profil.');
  String get availableAmount => _t('المبلغ المتاح', 'Montant Disponible');
  String get unavailableAmount => _t('المبلغ غير المتاح', 'Montant Non Disponible');
  String get unavailable => _t('غير متوفر', 'Indisponible');
  String get language => _t('اللغة', 'Langue');
  String get arabic => _t('العربية', 'Arabe');
  String get french => _t('الفرنسية', 'Français');
  String get chooseLanguage => _t('اختر لغتك', 'Choisissez votre langue');
  String get continueLabel => _t('متابعة', 'Continuer');
  String get onboardingSkip => _t('تخطي', 'Passer');
  String get onboardingNext => _t('التالي', 'Suivant');
  String get onboardingStart => _t('ابدأ', 'Commencer');
  String get onboardingTitle1 =>
      _t('أرسل طرودك بسهولة', 'Envoyez vos colis facilement');
  String get onboardingBody1 => _t(
        'أنشئ طلب توصيل في دقائق: المنتج، العنوان، والولاية.',
        'Créez une commande en quelques minutes : produit, adresse et gouvernorat.',
      );
  String get onboardingTitle2 =>
      _t('تابع كل مرحلة', 'Suivez chaque étape');
  String get onboardingBody2 => _t(
        'من إنشائه إلى التسليم: جارٍ، بالمستودع، في الطريق، ثم مسلَّم.',
        'De la création à la livraison : En cours, En dépôt, En route, puis livré.',
      );
  String get onboardingTitle3 =>
      _t('مدفوعاتك في مكان واحد', 'Vos paiements au même endroit');
  String get onboardingBody3 => _t(
        'اطّلع على الرصيد والمعاملات بعد تأكيد التسليم.',
        'Consultez le solde et les transactions après confirmation de livraison.',
      );
  String get completeProfileTitle =>
      _t('أكمل معلومات المرسِل', 'Complétez le profil expéditeur');
  String get completeProfileSubtitle => _t(
        'حسابك جاهز للدخول. أضف البيانات الناقصة لمتابعة العمل.',
        'Votre compte est prêt. Ajoutez les informations manquantes pour continuer.',
      );
  String get company => _t('الشركة / المحل', 'Société / boutique');
  String get cin => _t('ب.ت.و / المعرف الجبائي', 'CIN / matricule fiscale');
  String get saveProfile => _t('حفظ ومتابعة', 'Enregistrer et continuer');
  String get profileSavedLocally => _t(
        'تم حفظ البيانات على هذا الجهاز. الخادم لا يقبل تعديل الملف بعد.',
        'Informations enregistrées sur cet appareil. Le serveur n’accepte pas encore la mise à jour du profil.',
      );
  String get profileSaved =>
      _t('تم حفظ الملف الشخصي', 'Profil enregistré');
  String get completeYourProfile =>
      _t('أكمل ملفك', 'Compléter le profil');
  String get editProfile => _t('تعديل الملف', 'Modifier le profil');
  String get personalInfo =>
      _t('المعلومات الشخصية', 'Informations personnelles');
  String get security => _t('الأمان', 'Sécurité');

  String get dashboard => _t('لوحة التحكم', 'Tableau de Bord');
  String get deliveryCircuit => _t('مسار التوصيل', 'Circuit de Livraison');
  String get orderTracking => _t('متابعة الطرود', 'Suivi des Commandes');
  String get notifications => _t('الإشعارات', 'Notifications');
  String get home => _t('الرئيسية', 'Accueil');
  String helloName(String name) => _t('مرحباً، $name', 'Bonjour, $name');
  String get parcelsTotal => _t('طرداً إجمالاً', 'colis au total');
  String get inCirculation => _t('قيد التوصيل', 'En circulation');
  String get deliveredShare => _t('مُسلَّمة', 'Livrés');
  String get paidShare => _t('مدفوعة', 'Payés');
  String get distribution => _t('التوزيع', 'Répartition');
  String get seeAll => _t('عرض الكل', 'Voir tout');
  String get newRules => _t('القواعد الجديدة', 'القواعد الجديدة');
  String percentOf(double value) =>
      _t('${value.toStringAsFixed(1)} ٪', '${value.toStringAsFixed(1)} %');
  String get orders => _t('الطلبات', 'Commandes');
  String get add => _t('إضافة', 'Ajouter');
  String get transactions => _t('المعاملات', 'Transactions');
  String get senderDashboard =>
      _t('لوحة تحكم المرسِل', 'Tableau de Bord Expéditeur');
  String get myOrders => _t('طلباتي', 'Mes Commandes');
  String get addOrder => _t('إضافة طلب', 'Ajouter une Commande');
  String get myTransactions => _t('معاملاتي', 'Mes Transactions');
  String get driverDashboard =>
      _t('لوحة تحكم الموصّل', 'Tableau de Bord Livreur');
  String get circuit => _t('المسار', 'Circuit');
  String get parcels => _t('الطرود', 'Colis');

  String get userStats => _t('إحصائيات المستخدمين', 'Statistiques des Utilisateurs');
  String get resourceTracking => _t('متابعة الموارد', 'Suivi des Ressources');
  String get senders => _t('المرسِلون', 'Expéditeurs');
  String get drivers => _t('الموصّلون', 'Livreurs');
  String get vehicles => _t('المركبات', 'Véhicules');
  String get all => _t('الكل', 'Tous');
  String get inProgress => _t('جارٍ', 'En cours');
  String get inDepot => _t('في المستودع', 'En dépôt');
  String get inRoute => _t('في الطريق', 'En route');
  String get delivered => _t('تم التسليم', 'Livré');
  String get paid => _t('مدفوع', 'Payé');
  String get unpaid => _t('غير مدفوع', 'Non payé');
  String get redeliver => _t('إعادة التسليم', 'Relivrer');
  String get cancelled => _t('ملغى', 'Annulé');
  String weekDeliveries(int n) =>
      _t('تسليمات هذا الأسبوع : $n', 'Livraisons cette semaine : $n');
  String enRouteAmount(String amount) =>
      _t('مبالغ في الطريق : $amount', 'Montant en route : $amount');
  String get topDestinations =>
      _t('أكثر الوجهات', 'Destinations les plus fréquentes');
  String get parcelsToday => _t('طرود اليوم', 'Colis du jour');
  String get thisWeek => _t('هذا الأسبوع', 'Cette semaine');
  String get destinations => _t('الوجهات', 'Destinations');
  String get recentParcels => _t('آخر الطرود', 'Derniers colis');
  String transactionsSummary(int unpaid, int paid) => _t(
        '$unpaid غير مدفوعة · $paid مدفوعة. مبلغ الطرود ورسوم التوصيل.',
        '$unpaid non payés · $paid payés. Montant des colis et frais de livraison.',
      );
  String get parcelsUnavailable =>
      _t('الطرود غير متاحة.', 'Colis indisponibles.');
  String get cannotLoadDashboard =>
      _t('تعذر تحميل لوحة التحكم.', 'Impossible de charger le tableau de bord.');

  String get searchByNumber => _t('بحث بالرقم', 'Rechercher par numéro');
  String get filterByStatus => _t('تصفية حسب الحالة', 'Filtrer par statut');
  String orderCount(int n) => _t('$n طلب', '$n commande(s)');
  String orderCountWithSum(int n, String sum) =>
      _t('$n طلب — $sum د.ت', '$n commande(s) — $sum TND');
  String get noOrders => _t('لا توجد طلبات', 'Aucune commande trouvée');
  String get cannotLoadOrders =>
      _t('تعذر تحميل الطلبات.', 'Impossible de charger les commandes.');
  String orderTitle(String id) => _t('طلب $id', 'Commande $id');
  String clientName(String name) => _t('الزبون: $name', 'Client: $name');
  String dateLabel(String date) => _t('التاريخ: $date', 'Date: $date');
  String get orderDetails => _t('تفاصيل الطلب', 'Détails de la Commande');
  String get view => _t('عرض', 'Voir');
  String get print => _t('طباعة', 'Imprimer');
  String get orderNotFound => _t('الطلب غير موجود', 'Commande introuvable');
  String get cannotLoadOrder =>
      _t('تعذر تحميل الطلب.', 'Impossible de charger la commande.');
  String get forbiddenOrder => _t(
        'دخول مرفوض: هذا الطلب غير مُسند لحسابك.',
        'Accès refusé : cette commande n’est pas assignée à votre compte.',
      );

  String get client => _t('الزبون', 'Client');
  String get name => _t('الاسم', 'Nom');
  String get address => _t('العنوان', 'Adresse');
  String get city => _t('المدينة', 'Ville');
  String get delivery => _t('التوصيل', 'Livraison');
  String get orderDate => _t('تاريخ الطلب', 'Date de commande');
  String get type => _t('النوع', 'Type');
  String get deliveryDate => _t('تاريخ التوصيل', 'Date de livraison');
  String get deliveryFees => _t('رسوم التوصيل', 'Frais de livraison');
  String get colisPrice => _t('سعر الطرد', 'Prix du colis');
  String get product => _t('المنتج', 'Produit');
  String get price => _t('السعر', 'Prix');
  String get fragile => _t('قابل للكسر', 'Fragile');
  String get yes => _t('نعم', 'Oui');
  String get no => _t('لا', 'Non');
  String get openBeforePay =>
      _t('فتح قبل الدفع', 'Ouvrir avant paiement');
  String get sender => _t('المرسِل', 'Expéditeur');
  String reasonLabel(String reason) => _t('السبب : $reason', 'Motif : $reason');
  String get reliverNow => _t('إعادة التسليم الآن', 'Relivrer maintenant');
  String get markPaid => _t('تعيين كمدفوع', 'Marquer payé');
  String get returnDepot => _t('إرجاع للمستودع', 'Retour dépôt');
  String get deleteOrder => _t('حذف هذا الطلب؟', 'Supprimer cette commande ?');
  String get deleteForever => _t('هذا الإجراء نهائي.', 'Cette action est définitive.');
  String get cancel => _t('إلغاء', 'Annuler');
  String get delete => _t('حذف', 'Supprimer');
  String get markedPaid => _t('تم تعليم الطرد كمدفوع', 'Colis marqué payé');
  String get returnedToDepot => _t('أُعيد الطرد إلى المستودع', 'Colis retourné en dépôt');
  String get rescheduledDepot =>
      _t('أُعيد جدولة الطرد في المستودع', 'Colis replanifié en dépôt');
  String get updateError =>
      _t('خطأ أثناء التحديث.', 'Erreur lors de la mise à jour.');

  String get scanQr => _t('مسح رمز QR', 'Scanner le QR Code');
  String get scanHint => _t('امسح رمز QR', 'Scannez un QR code');
  String codeLabel(String code) => _t('الرمز : $code', 'Code : $code');
  String get enterOrderNumber =>
      _t('أدخل رقم الطلب', 'Saisir le numéro de commande');
  String get orderNumberHint => _t('مثال : 83682', 'Ex : 83682');
  String get validate => _t('تأكيد', 'Valider');
  String get confirmReceiveDepot =>
      _t('تأكيد الاستلام في المستودع؟', 'Confirmer la réception au dépôt ?');
  String get continueAction => _t('متابعة', 'Continuer');
  String get loadInRoute =>
      _t('تحميل هذا الطرد في الجولة (في الطريق)؟', 'Charger ce colis dans la tournée (En route) ?');
  String get confirm => _t('تأكيد', 'Confirmer');
  String get close => _t('إغلاق', 'Fermer');
  String get chooseOutcome =>
      _t('اختر نتيجة التوصيل', 'Choisissez le résultat de livraison');
  String get reasonRequired => _t('السبب (مطلوب)', 'Motif (obligatoire)');
  String get enterReason => _t('يرجى إدخال السبب.', 'Veuillez entrer un motif.');
  String get parcelInRoute => _t('الطرد في الطريق', 'Colis en route');
  String get parcelDelivered => _t('تم تسليم الطرد', 'Colis livré');
  String get parcelToRedeliver => _t('الطرد لإعادة التسليم', 'Colis à relivrer');
  String get parcelCancelled => _t('أُلغي الطرد', 'Colis annulé');
  String get parcelConfirmed => _t('تم تأكيد الطرد بنجاح', 'Colis confirmé avec succès');
  String get unknownStatus => _t('حالة غير معروفة', 'Statut inconnu');
  String get parcelNotFound => _t('الطلب غير موجود!', 'Commande introuvable!');
  String get scanNotAssigned => _t(
        'هذا الطرد ليس على المركبة المسندة إليك.',
        'Ce colis n’est pas sur le véhicule qui vous est assigné.',
      );
  String get currentStatus => _t('الحالة الحالية', 'Statut actuel');
  String get fillAllFields =>
      _t('يرجى ملء كل الحقول', 'Veuillez remplir tous les champs');
  String get confirmError =>
      _t('خطأ أثناء تأكيد الطرد', 'Erreur lors de la confirmation du colis');
  String get cannotLoadParcel =>
      _t('خطأ أثناء جلب تفاصيل الطرد', 'Erreur lors de la récupération des détails du colis');

  String get selectCar => _t('اختر السيارة', 'Sélectionnez la voiture');
  String get selectVehicle => _t('اختر مركبة', 'Sélectionner un véhicule');
  String get chooseDate => _t('اختر تاريخاً', 'Choisissez une date');
  String totalOrders(int n) => _t('إجمالي الطلبات: $n', 'Commandes totales: $n');
  String get noDeliveries =>
      _t('لا توجد توصيلات لهذا الاختيار', 'Aucune livraison pour cette sélection');
  String get cannotLoadVehicles =>
      _t('تعذر تحميل المركبات.', 'Impossible de charger les véhicules.');
  String get cannotLoadDeliveries =>
      _t('تعذر تحميل التوصيلات.', 'Impossible de charger les livraisons.');
  String get noVehicleSelected =>
      _t('لم يتم اختيار مركبة!', 'Aucun véhicule sélectionné!');
  String get noDriverAssigned =>
      _t('لا موصّل مُسند لهذه المركبة', 'Aucun livreur assigné à ce véhicule');
  String get noVehicleAssigned =>
      _t('لا توجد مركبة مُسندة إليك.', 'Aucun véhicule assigné.');
  String get generateCircuit => _t('إنشاء مسار', "Génération d'un circuit");
  String get cannotGenerateCircuit =>
      _t('تعذر إنشاء المسار.', 'Impossible de générer le circuit.');
  String get unknown => _t('غير معروف', 'Unknown');

  String get payments => _t('المدفوعات', 'Paiements');
  String get selectDriver => _t('اختر موصّلاً', 'Sélectionner un livreur');
  String get cannotLoadDrivers =>
      _t('تعذر تحميل الموصّلين.', 'Impossible de charger les livreurs.');
  String get noDriversFound =>
      _t('لا يوجد موصّلون.', 'Aucun livreur disponible.');
  String collectedTotal(String amount) =>
      _t('المجموع المحصّل : $amount د.ت', 'Total collecté : $amount TND');
  String deliveryFeesLine(String amount) =>
      _t('رسوم التوصيل : $amount د.ت', 'Frais de livraison : $amount TND');
  String cancellationFeesLine(String amount) =>
      _t('رسوم الإلغاء : $amount د.ت', 'Frais d\'annulation : $amount TND');
  String get confirmPayment => _t('تأكيد الدفع', 'Confirmer le paiement');
  String paymentConfirmed(int credits, int penalties) => _t(
        'تم تأكيد الدفع ($credits رصيد، $penalties غرامة).',
        'Paiement confirmé ($credits crédit(s), $penalties pénalité(s)).',
      );
  String get paymentError => _t('خطأ أثناء الدفع', 'Erreur lors du paiement');
  String amountLine(String amount) => _t('المبلغ : $amount د.ت', 'Montant : $amount TND');

  String get vehicleList => _t('قائمة المركبات', 'Liste des Véhicules');
  String get noVehicles => _t('لا توجد مركبات', 'Aucun véhicule disponible');
  String get addVehicle => _t('إضافة مركبة', 'Ajouter un véhicule');
  String get plate => _t('رقم اللوحة', 'Matricule');
  String get model => _t('الطراز', 'Modèle');
  String get cannotAddVehicle =>
      _t('تعذر إضافة المركبة.', 'Impossible d\'ajouter le véhicule.');
  String get vehicleDetails => _t('تفاصيل المركبة', 'Détails du Véhicule');
  String get cannotLoadVehicle =>
      _t('تعذر تحميل المركبة.', 'Impossible de charger le véhicule.');
  String get cannotLoadDriver =>
      _t('تعذر تحميل الموصّل.', 'Impossible de charger le livreur.');
  String get cannotAssignDriver =>
      _t('تعذر تعيين الموصّل.', 'Impossible d\'assigner le livreur.');
  String driverLine(String name) => _t('الموصّل: $name', 'Livreur: $name');
  String get noDriver => _t('لا موصّل مُسند', 'Aucun livreur assigné');
  String phoneLine(String phone) => _t('الهاتف: $phone', 'Téléphone: $phone');
  String get changeDriver => _t('تغيير الموصّل', 'Changer le livreur');
  String get assignDriver => _t('تعيين موصّل', 'Assigner un livreur');
  String get deliveryChanged => _t('تم تغيير الموصّل', 'Livreur modifié');
  String get putInRoute => _t('تعيين وفي الطريق', 'Mettre En route');
  String get chooseLivreurFirst =>
      _t('اختر موصّلاً أولاً', 'Veuillez choisir un livreur');
  String get assignedOrders => _t('الطلبات المسندة:', 'Commandes assignées:');
  String get assignedOrdersDriver =>
      _t('الطلبات المسندة لهذا الموصّل:', 'Commandes assignées à ce livreur:');
  String get assignedOrdersClient =>
      _t('طلبات هذا الزبون:', 'Commandes de ce client:');
  String get na => _t('غ/م', 'N/A');

  String listOf(String role) => _t('قائمة $role', 'Liste des $role');
  String get roleSenders => _t('المرسِلين', 'Expéditeurs');
  String get roleDrivers => _t('الموصّلين', 'Livreurs');
  String get roleAgents => _t('الوكلاء', 'Agents');
  String get users => _t('المستخدمين', 'Utilisateurs');
  String get cannotLoadUsers =>
      _t('تعذر تحميل المستخدمين.', 'Impossible de charger les utilisateurs.');
  String noneFound(String role) => _t('لا يوجد $role', 'Aucun $role trouvé');
  String get unknownName => _t('اسم غير معروف', 'Nom inconnu');
  String get unknownEmail => _t('بريد غير معروف', 'Email inconnu');
  String get userDetails => _t('تفاصيل المستخدم', "Détails de l'utilisateur");
  String get cannotLoadUser =>
      _t('تعذر تحميل هذا المستخدم.', 'Impossible de charger cet utilisateur.');
  String emailLine(String email) => _t('البريد: $email', 'Email: $email');
  String roleLine(String role) => _t('الدور: $role', 'Rôle: $role');
  String get withdrawAll => _t('سحب الكل', 'Retirer Tout');
  String withdrawn(String amount) =>
      _t('تم سحب $amount د.ت', 'Retrait de $amount TND effectué!');
  String get withdrawError => _t('خطأ أثناء السحب', 'Erreur lors du retrait');
  String get createAccount => _t('إنشاء حساب', 'Créer un');
  String get createTheAccount => _t('إنشاء الحساب', 'Créer le compte');
  String get productInfo => _t('معلومات المنتج', 'Informations Produit');
  String get productName => _t('اسم المنتج', 'Nom du Produit');
  String get quantityKg => _t('الكمية (كغ)', 'Quantité (kg)');
  String get pricePerKg => _t('السعر/كغ', 'Prix/Kg');
  String get clientInfo => _t('معلومات الزبون', 'Informations Client');
  String get clientNameField => _t('اسم الزبون', 'Nom du Client');
  String get governorate => _t('الولاية', 'Gouvernorat');
  String get requiredField => _t('حقل مطلوب', 'Champ requis');
  String get deliveryFeesNote =>
      _t('ملاحظة : رسوم التوصيل', 'Note : frais de livraison');
  String get nearbyGovernorates =>
      _t('8 د.ت (ولايات قريبة)', '8 DT (gouvernorats proches)');
  String get farGovernorates =>
      _t('9 د.ت (ولايات بعيدة)', '9 DT (gouvernorats éloignés)');
  String get extraWeightFee => _t(
        'إذا تجاوز الوزن 10 كغ، يُحتسب 1 د.ت إضافي لكل كغ.',
        'Si le poids dépasse 10 kg, 1 DT supplémentaire est facturé par kg.',
      );
  String get signup => _t('التسجيل', 'Inscription');
  String get accountCreated =>
      _t('تم إنشاء الحساب بنجاح', 'Compte créé avec succès !');
  String errorLine(String e) => _t('خطأ : $e', 'Erreur : $e');
  String get save => _t('حفظ', 'Enregistrer');

  String get adminPanel => _t('لوحة المشرف', 'Panel Administrateur');
  String get managePlatform => _t('أدِر منصتك', 'Gérez votre plateforme');
  String get manageAgents => _t('إدارة الوكلاء', 'Gestion des Agents');
  String get manageDrivers => _t('إدارة الموصّلين', 'Gestion des Livreurs');
  String get vehicleFleet => _t('أسطول المركبات', 'Parc Véhicules');
  String get paymentManagement => _t('إدارة المدفوعات', 'Gestion Paiements');
  String get referenceData => _t('المرجع', 'Référentiel');
  String get gouvernoratsTab => _t('الولايات', 'Gouvernorats');
  String get villesTab => _t('المدن', 'Villes');
  String get secteursTab => _t('القطاعات', 'Secteurs');
  String get showArchived => _t('إظهار المؤرشفة', 'Afficher les archivés');
  String get renameGouvernorat => _t('تصحيح الولاية', 'Corriger le gouvernorat');
  String get mergeGouvernorat => _t('دمج', 'Fusionner');
  String get archive => _t('أرشفة', 'Archiver');
  String get restore => _t('استعادة', 'Réactiver');
  String get unrecognized => _t('غير معروف', 'Non reconnu');
  String get duplicate => _t('مكرر', 'Doublon');
  String get archived => _t('مؤرشف', 'Archivé');
  String get noGouvernorats => _t('لا توجد ولايات', 'Aucun gouvernorat');
  String get noVilles => _t('لا توجد مدن', 'Aucune ville');
  String get noSecteurs => _t('لا توجد قطاعات', 'Aucun secteur');
  String get addVille => _t('إضافة مدينة', 'Ajouter une ville');
  String get editVille => _t('تعديل المدينة', 'Modifier la ville');
  String get addSecteur => _t('إضافة قطاع', 'Ajouter un secteur');
  String get editSecteur => _t('تعديل القطاع', 'Modifier le secteur');
  String get routeOrder => _t('ترتيب المرور', 'Ordre de passage');
  String get noneOption => _t('بدون', 'Aucun');
  String get staffNewOrder => _t('طلب جديد', 'Nouvelle commande');
  String get chooseSender => _t('اختر المرسِل', 'Choisissez un expéditeur');
  String get searchSenderHint =>
      _t('الاسم أو الهاتف', 'Nom ou téléphone');
  String get adminTransactionsHint => _t(
        'الطرد المسلّم يبقى غير مدفوع حتى يؤكد المشرف الدفع.',
        'Un colis livré reste dans Non payé. Il passe dans Payé quand un administrateur confirme le paiement.',
      );
  String get parcelAmount => _t('مبلغ الطرود', 'Montant des colis');
  String get searchOrdersHint => _t(
        'رقم، طرد، مرسِل، هاتف',
        'N°, colis, expéditeur, téléphone',
      );
  String get cannotLoadReference =>
      _t('تعذر تحميل المرجع.', 'Impossible de charger le référentiel.');
  String get searchVilleHint =>
      _t('ابحث عن مدينة', 'Rechercher une ville');
  String get chooseVille => _t('اختر مدينة', 'Choisissez une ville');
  String get chooseGovernorateFirst =>
      _t('اختر الولاية أولاً', "Choisissez d'abord le gouvernorat");
  String get villeRequired =>
      _t('المدينة مطلوبة', 'La ville est obligatoire');
  String get noSecteur => _t('بدون قطاع', 'Sans secteur');
  String moreVillesHint(int n) => _t(
        '$n مدن أخرى: حدّد البحث.',
        '$n autres villes : précisez la recherche.',
      );
  String get referenceSaved => _t('تم الحفظ', 'Enregistré');
  String get referenceDeleted => _t('تم الحذف', 'Supprimé');
  String get confirmDelete => _t('تأكيد الحذف؟', 'Confirmer la suppression ?');
  String get mergeInto => _t('الإبقاء على', 'Garder');
  String get usageUnknown =>
      _t('الاستخدام غير معروف', 'Utilisation inconnue');
  String usageCounts(int tickets, int villes) => _t(
        '$tickets طلب · $villes مدينة',
        '$tickets commande(s) · $villes ville(s)',
      );
  String get feesShort => _t('رسوم', 'Frais');
  String get search => _t('بحث', 'Rechercher');
  String get loadMore => _t('تحميل المزيد', 'Charger plus');
  String get more => _t('المزيد', 'Plus');

  String get scanToUpdate =>
      _t('امسح الطرد لتحديث الحالة', 'Scannez un colis pour mettre à jour le statut');
  String get assignedParcels => _t('الطرود المسندة', 'Colis assignés');

  String get parcelSummary => _t('ملخص الطرود', 'Résumé des Colis');
  String totalParcels(int n) => _t('إجمالي الطرود : $n', 'Total des colis : $n');
  String deliveredParcels(int n) => _t('طرود مسلّمة : $n', 'Colis livrés : $n');
  String get parcelStats => _t('إحصائيات الطرود', 'Statistiques des Colis');
  String get totalRevenue => _t('إجمالي الإيرادات', 'Revenus totaux');
  String get cannotLoadStats =>
      _t('تعذر تحميل الإحصائيات.', 'Impossible de charger les statistiques.');
  String get orderList => _t('قائمة الطلبات', 'Liste des Commandes');
  String totalPrice(String amount) =>
      _t('السعر الإجمالي: $amount د.ت', 'Prix Total: $amount TND');
  String deliveryDateLine(String date) =>
      _t('تاريخ التوصيل: $date', 'Date de Livraison: $date');
  String get forbiddenOrders => _t(
        'دخول مرفوض: هذه الطلبات غير مسندة لك.',
        'Accès refusé : ces commandes ne vous sont pas assignées.',
      );

  String get notificationsNone =>
      _t('لا توجد إشعارات', 'Aucune notification disponible');
  String get cannotLoadNotifications =>
      _t('تعذر تحميل الإشعارات.', 'Impossible de charger les notifications.');
  String get cannotMarkRead =>
      _t('تعذر التعليم كمقروء', 'Impossible de marquer comme lu');
  String get notificationDeleted => _t('تم حذف الإشعار', 'Notification supprimée');
  String get cannotDeleteNotification =>
      _t('تعذر حذف الإشعار', 'Impossible de supprimer la notification');

  String get noTransactions =>
      _t('لا توجد معاملات', 'Aucune transaction trouvée');
  String get cannotLoadTransactions =>
      _t('تعذر تحميل المعاملات.', 'Impossible de charger les transactions.');
  String get feesByGov =>
      _t('رسوم التوصيل حسب الولاية', 'Frais de livraison par gouvernorat');
  String get notAuthenticated =>
      _t('المستخدم غير مسجّل الدخول.', 'Utilisateur non authentifié.');
  String get orderAdded =>
      _t('تمت إضافة الطلب بنجاح', 'Commande ajoutée avec succès!');
  String get addOrderError =>
      _t('خطأ أثناء إضافة الطلب.', "Erreur lors de l'ajout de la commande.");
  String get invalidOrderData =>
      _t('بيانات الطلب غير صالحة.', 'Données de commande invalides.');
  String get addAtLeastOneProduct =>
      _t('أضف منتجاً واحداً على الأقل.', 'Ajoutez au moins un produit.');
  String get addProduct => _t('إضافة منتج', 'Ajouter un produit');
  String get removeProduct => _t('حذف المنتج', 'Retirer le produit');
  String productNumber(int n) => _t('منتج $n', 'Produit $n');
  String get submitOrder => _t('إضافة الطلب', 'Ajouter la commande');
  String get canOpenBeforePay =>
      _t('يمكن الفتح قبل الدفع', 'Peut ouvrir avant de payer');
  String get productList => _t('قائمة المنتجات', 'Liste des produits');
  String get weeklyPlan => _t('الخطة الأسبوعية', 'Plan hebdomadaire');
  String get tarifs => _t('التعريفات', 'Tarifs');
  String get total => _t('المجموع', 'Total');
  String priceReturn(String price, String ret) =>
      _t('السعر: $price - الإرجاع: $ret', 'Prix: $price - Retour: $ret');

  String get status => _t('الحالة', 'Statut');
  String get loading => _t('جاري التحميل', 'Chargement');
  String get accessDenied => _t('دخول مرفوض', 'Accès refusé');
  String get notFound => _t('غير موجود', 'Introuvable');
  String get transitionRefused => _t('رُفض الانتقال.', 'Transition refusée.');
  String get unexpectedError => _t('حدث خطأ.', 'Une erreur est survenue.');
  String get unexpectedResponse =>
      _t('رد غير متوقع من الخادم.', 'Réponse serveur inattendue.');

  String get nameUnavailable => _t('الاسم غير متوفر', 'Nom indisponible');
  String get emailUnavailable => _t('البريد غير متوفر', 'Email indisponible');
  String get financeStats =>
      _t('الإحصائيات المالية', 'Statistiques financières');
  String get updatePasswordTitle =>
      _t('تحديث كلمة المرور', 'Mettre à jour le mot de passe');
  String get enterCurrentPassword =>
      _t('أدخل كلمة المرور الحالية', 'Veuillez entrer votre mot de passe actuel');
  String get currency => _t('د.ت', 'TND');
  String get noDetailsFound => _t('لا توجد تفاصيل', 'Aucun détail trouvé');
  String get noOrdersForSelection =>
      _t('لا توجد طلبات لهذا الاختيار', 'Aucune commande pour cette sélection');
  String get agents => _t('الوكلاء', 'Agents');
  String amountTnd(String amount) => _t('$amount د.ت', '$amount TND');
  String get deliveryRules => _t('قواعد التوصيل', 'Règles de livraison');
  String get rulePacked =>
      _t('يجب تغليف الطرود جيداً.', 'Les colis doivent être bien emballés.');
  String get rulePayConfirm => _t(
        'يجب تأكيد الدفع قبل الإرسال.',
        'Le paiement doit être confirmé avant l\'envoi.',
      );
  String get ruleReturnFees => _t(
        'تُطبَّق رسوم على الإرجاع حسب الحجم.',
        'Des frais s\'appliquent aux retours selon le volume.',
      );
  String get orderStats => _t('إحصائيات الطلبات', 'Statistiques des Commandes');
  String get parcelTarifs => _t('تعريفات الطرود', 'Tarifs des Colis');
  String get roleAgent => _t('وكيل', 'Agent');
  String get roleAdmin => _t('مشرف', 'Administrateur');
  String get roleSender => _t('مرسِل', 'Expéditeur');
  String get roleDriver => _t('موصّل', 'Livreur');
  String get noName => _t('بدون اسم', 'Sans nom');
  String get parcelDetails => _t('تفاصيل الطرد', 'Détails du Colis');
  String parcelTitle(String id) => _t('طرد $id', 'Colis $id');
  String get selectDeliveryDate =>
      _t('اختر تاريخ التوصيل', 'Sélectionner une date de livraison');
  String get chooseVehicle => _t('اختر مركبة', 'Choisissez un véhicule');
  String get currentStatusColon => _t('الحالة الحالية :', 'Statut actuel :');
  String parcelStatusLine(String id, String status) =>
      _t('طرد $id — ${statusLabel(status, this)}', 'Colis $id — ${statusLabel(status, this)}');

  String roleTitle(String role) {
    switch (role) {
      case 'business_client':
        return roleSenders;
      case 'delivery_person':
        return roleDrivers;
      case 'agent':
        return roleAgents;
      case 'admin':
        return roleAdmin;
      default:
        return users;
    }
  }

  String roleSingular(String role) {
    switch (role) {
      case 'business_client':
        return roleSender;
      case 'delivery_person':
        return roleDriver;
      case 'agent':
        return roleAgent;
      case 'admin':
        return roleAdmin;
      default:
        return users;
    }
  }
}

String statusLabel(String api, [AppStrings? strings]) {
  final s = strings ?? LocaleController.instance.s;
  switch (api.trim()) {
    case 'Tous':
      return s.all;
    case 'En cours':
    case 'CREATED':
      return s.inProgress;
    case 'En dépôt':
    case 'IN_DEPOT':
      return s.inDepot;
    case 'En route':
    case 'IN_ROUTE':
      return s.inRoute;
    case 'Livrer':
    case 'Livré':
    case 'DELIVERED':
      return s.delivered;
    case 'Relivrer':
    case 'REDELIVER':
      return s.redeliver;
    case 'Annuler':
    case 'Annulé':
    case 'REJECTED':
      return s.cancelled;
    case 'Payé':
    case 'Paye':
      return s.paid;
    case 'Non payé':
      return s.unpaid;
    default:
      return api;
  }
}
