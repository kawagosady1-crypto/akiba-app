String currentLang = 'sw';

/// Each entry: [English, Kiswahili]
const Map<String, List<String>> _s = {
  // ---- general ----
  'hello': ['Hi', 'Habari'],
  'home': ['Home', 'Nyumbani'],
  'goals': ['Goals', 'Malengo'],
  'history': ['History', 'Historia'],
  'insights': ['Insights', 'Takwimu'],
  'rewards': ['Rewards', 'Zawadi'],
  'settings': ['Settings', 'Mipangilio'],
  'log': ['Log', 'Ingiza'],
  'save': ['Save', 'Hifadhi'],
  'cancel': ['Cancel', 'Ghairi'],
  'delete': ['Delete', 'Futa'],
  'ok': ['OK', 'Sawa'],
  'close': ['Close', 'Funga'],
  'stop': ['Stop', 'Acha'],
  'off': ['Off', 'Zima'],
  'today': ['Today', 'Leo'],
  'yesterday': ['Yesterday', 'Jana'],
  'otherDay': ['Other day', 'Siku nyingine'],
  'date': ['Date', 'Tarehe'],
  'days': ['Days', 'Siku'],
  'note': ['Note (optional)', 'Maelezo (si lazima)'],
  'amount': ['Amount (TZS)', 'Kiasi (TZS)'],
  'amountShort': ['Amount', 'Kiasi'],
  'item': ['Item', 'Kipengele'],
  'total': ['Total', 'Jumla'],
  'balance': ['Balance', 'Salio'],
  'of': ['of', 'kati ya'],
  'nothingYet': ['Nothing yet', 'Bado hakuna kitu'],
  'noEntries': ['No entries yet', 'Bado hakuna kumbukumbu'],
  'about': ['About', 'Kuhusu'],
  'required': ['Please fill in the name', 'Tafadhali jaza jina'],
  'invalidAmount': ['Enter a valid amount', 'Weka kiasi sahihi'],

  // ---- onboarding ----
  'welcome': ['Welcome to Akiba', 'Karibu Akiba'],
  'welcomeSub': [
    'Turn your big goal into small daily steps.',
    'Geuza lengo lako kubwa kuwa hatua ndogo za kila siku.'
  ],
  'language': ['Language', 'Lugha'],
  'yourName': ['Your name', 'Jina lako'],
  'firstGoal': ['Your main saving goal', 'Lengo lako kuu la akiba'],
  'start': ['Start saving', 'Anza kuweka akiba'],
  'dailyTargetPreview': ['Daily target', 'Lengo la kila siku'],
  'changeLater': [
    'You can change to weekly, monthly or your own amount later in Settings.',
    'Unaweza kubadilisha kuwa kila wiki, kila mwezi au kiasi chako baadaye kwenye Mipangilio.'
  ],

  // ---- goals ----
  'goal': ['Goal', 'Lengo'],
  'mainGoal': ['Main goal', 'Lengo kuu'],
  'miniGoal': ['Mini-goal', 'Lengo dogo'],
  'miniGoals': ['Mini-goals', 'Malengo madogo'],
  'noMainGoal': ['You have no main goal yet', 'Bado huna lengo kuu'],
  'createGoal': ['Create goal', 'Unda lengo'],
  'newGoal': ['New goal', 'Lengo jipya'],
  'editGoal': ['Edit goal', 'Hariri lengo'],
  'addMini': ['Add mini-goal', 'Ongeza lengo dogo'],
  'goalName': ['What are you saving for?', 'Unaweka akiba kwa ajili ya nini?'],
  'goalAmount': ['Goal amount (TZS)', 'Kiasi cha lengo (TZS)'],
  'alreadySaved': ['Already saved (TZS)', 'Ulichokwisha kuweka (TZS)'],
  'alreadySavedHelp': [
    'Leave empty if you are starting from zero',
    'Acha wazi kama unaanza na sifuri'
  ],
  'startTooBig': [
    'Already saved must be less than the goal amount',
    'Ulichokwisha kuweka kiwe chini ya kiasi cha lengo'
  ],
  'whereKept': ['Where is that money kept?', 'Pesa hizo ziko wapi?'],
  'startingAmount': ['Starting amount', 'Kiasi cha kuanzia'],
  'deadline': ['Deadline', 'Tarehe ya mwisho'],
  'deadlinePast': ['Deadline must be after today', 'Tarehe lazima iwe baada ya leo'],
  'deadlinePassed': ['Deadline passed', 'Muda umepita'],
  'due': ['Due', 'Mwisho'],
  'daysLeft': ['days left', 'siku zimebaki'],
  'dayOf': ['Day {a} of {b}', 'Siku {a} kati ya {b}'],
  'saved': ['Saved', 'Umeweka'],
  'goalDone': ['Goal reached! Congratulations', 'Umefikia lengo! Hongera'],
  'startNewGoal': ['Start a new main goal', 'Anza lengo kuu jipya'],
  'archive': ['Mark as finished', 'Weka kama imekamilika'],
  'deleteGoal': ['Delete goal', 'Futa lengo'],
  'deleteGoalConfirm': [
    'Delete this goal and all its entries?',
    'Futa lengo hili na kumbukumbu zake zote?'
  ],
  'completed': ['Finished goals', 'Malengo yaliyokamilika'],
  'addPhoto': ['Add a photo of your goal', 'Ongeza picha ya lengo lako'],
  'changePhoto': ['Change photo', 'Badilisha picha'],
  'removePhoto': ['Remove', 'Ondoa'],
  'lockGoal': ['Lock this goal', 'Funga lengo hili'],
  'lockGoalHelp': [
    'Withdrawals wait 24 hours, except emergencies',
    'Kutoa pesa kunasubiri saa 24, isipokuwa dharura'
  ],
  'extraGoesTo': ['Extra goes to', 'Ziada inaenda'],
  'buffer': ['Emergency buffer', 'Akiba ya dharura'],

  // ---- targets and periods ----
  'target': ['Target', 'Lengo'],
  'actual': ['Actual', 'Halisi'],
  'todayTarget': ["Today's target", 'Lengo la leo'],
  'weekTarget': ["This week's target", 'Lengo la wiki hii'],
  'monthTarget': ["This month's target", 'Lengo la mwezi huu'],
  'savedToday': ['Saved today', 'Umeweka leo'],
  'savedThisWeek': ['Saved this week', 'Umeweka wiki hii'],
  'savedThisMonth': ['Saved this month', 'Umeweka mwezi huu'],
  'perDay': ['per day', 'kwa siku'],
  'perWeek': ['per week', 'kwa wiki'],
  'perMonth': ['per month', 'kwa mwezi'],
  'daily': ['Daily', 'Kila siku'],
  'weekly': ['Weekly', 'Kila wiki'],
  'monthly': ['Monthly', 'Kila mwezi'],
  'targetPeriod': ['Target period', 'Kipindi cha lengo'],
  'targetAmountMode': ['Target amount', 'Kiasi cha lengo'],
  'savingTarget': ['Saving target (main goal)', 'Lengo la akiba (lengo kuu)'],
  'auto': ['Automatic', 'Otomatiki'],
  'fixed': ['My own amount', 'Kiasi changu'],
  'fixedTag': ['your own amount', 'kiasi chako'],
  'fixedAmount': ['My amount (TZS)', 'Kiasi changu (TZS)'],
  'autoExplain': [
    'Calculated from your goal and deadline: {a} now.',
    'Linahesabiwa kutoka lengo na tarehe yako: {a} sasa.'
  ],
  'fixedFinish': [
    "At {a} you'll finish around {b}.",
    'Kwa {a} utamaliza karibu tarehe {b}.'
  ],
  'fixedLate': [
    'That is after your deadline ({c}). Raise the amount or extend the deadline.',
    'Hiyo ni baada ya tarehe yako ya mwisho ({c}). Ongeza kiasi au ongeza muda.'
  ],
  'fixedEarly': [
    'That is on or before your deadline.',
    'Hiyo ni kabla au siku ya tarehe yako ya mwisho.'
  ],
  'targetMet': ['Target met!', 'Umefikia lengo!'],
  'extraLabel': ['Extra', 'Ziada'],
  'remainingPeriod': ['Still to save', 'Bado kuweka'],
  'shortPrev': [
    'Last period you were short by {a}. Your target is now {b}.',
    'Kipindi kilichopita ulipungukiwa {a}. Lengo lako sasa ni {b}.'
  ],
  'missedPrev': [
    "You didn't save last period. Your target is now {b}.",
    'Kipindi kilichopita hukuweka akiba. Lengo lako sasa ni {b}.'
  ],
  'shortFixed': [
    'Last period you were short by {a}. Your target stays {b}; at this pace you finish around {c}.',
    'Kipindi kilichopita ulipungukiwa {a}. Lengo lako linabaki {b}; kwa kasi hii utamaliza karibu {c}.'
  ],
  'missedFixed': [
    "You didn't save last period. Your target stays {b}; at this pace you finish around {c}.",
    'Kipindi kilichopita hukuweka akiba. Lengo lako linabaki {b}; kwa kasi hii utamaliza karibu {c}.'
  ],
  'extendDeadline': ['Extend deadline', 'Ongeza muda'],

  // ---- home ----
  'pace': ['Your pace', 'Kasi yako'],
  'timeUsed': ['Time used', 'Muda uliotumika'],
  'moneySaved': ['Money saved', 'Pesa zilizowekwa'],
  'paceAhead': ["You're on pace or ahead. Keep going!", 'Uko kwenye kasi au mbele. Endelea hivyo!'],
  'paceBehind': [
    "You're behind: more time has passed than money saved.",
    'Uko nyuma: muda uliopita ni mwingi kuliko pesa ulizoweka.'
  ],
  'streak': ['Streak', 'Mfululizo'],
  'projected': ['Projected finish', 'Utamaliza karibu'],
  'noProjection': [
    'Save a few days to see your finish date',
    'Weka akiba siku chache uone tarehe ya kumaliza'
  ],
  'onTrack': ['On track', 'Uko sawa'],
  'behind': ['Behind schedule', 'Uko nyuma'],
  'extraPot': ['Extra pot', 'Mfuko wa ziada'],
  'extraTotal': ['Total extra saved', 'Jumla ya ziada'],
  'savedToday2': ['Saved today', 'Umeweka leo'],
  'spentToday': ['Spent today', 'Umetumia leo'],
  'incomeToday': ['Income today', 'Mapato ya leo'],
  'withdrawnToday': ['Withdrawn today', 'Umetoa leo'],
  'recent': ['Recent entries', 'Kumbukumbu za karibuni'],
  'seeAll': ['See all', 'Ona zote'],
  'loansTitle': ['Pay back your goals', 'Rudisha pesa za malengo'],
  'loanLine': ['{g}: {a} left of {b}', '{g}: {a} imebaki kati ya {b}'],
  'loanPlan': [
    'Plan: {a} per day, finish by {d}',
    'Mpango: {a} kwa siku, maliza kufikia {d}'
  ],
  'repayNow': ['Pay back now', 'Rudisha sasa'],
  'limitsTitle': ['Spending limits', 'Mipaka ya matumizi'],
  'limitStatusNamed': ['{c}: {a} of {b} this month', '{c}: {a} kati ya {b} mwezi huu'],

  // ---- log sheet ----
  'kindSave': ['Save', 'Weka'],
  'kindSpend': ['Spend', 'Tumia'],
  'kindWithdraw': ['Withdraw', 'Toa'],
  'kindIncome': ['Income', 'Mapato'],
  'location': ['Where is the money?', 'Pesa ziko wapi?'],
  'paidFrom': ['Paid from (optional)', 'Imelipwa kutoka (si lazima)'],
  'category': ['Category', 'Aina'],
  'incomeSource': ['Source', 'Chanzo'],
  'receivedIn': ['Received in', 'Imepokelewa kwenye'],
  'withdrawFrom': ['Withdraw from', 'Toa kutoka'],
  'takenFrom': ['Money taken from', 'Pesa zimetolewa kutoka'],
  'reason': ['Reason', 'Sababu'],
  'nothingToWithdraw': ['There are no savings to withdraw yet', 'Bado hakuna akiba ya kutoa'],
  'borrowFromSelf': ['Borrow from myself', 'Jikopeshe'],
  'borrowHelp': [
    'I will pay this money back to the goal',
    'Nitarudisha pesa hizi kwenye lengo'
  ],
  'payBackPlan': ['Pay back {a} per day for {d} days', 'Rudisha {a} kwa siku kwa siku {d}'],
  'countAsRepay': ['Count as loan repayment', 'Hesabu kama marejesho ya mkopo'],
  'owed': ['You still owe {a}', 'Bado unadaiwa {a}'],
  'impactAuto': [
    'After this, {p} goes from {a} to {b}.',
    'Baada ya hii, {p} litapanda kutoka {a} hadi {b}.'
  ],
  'impactFixed': [
    'After this, your finish date moves from {a} to {b}.',
    'Baada ya hii, tarehe ya kumaliza inahama kutoka {a} hadi {b}.'
  ],
  'lockedNotice': [
    'This goal is locked. Your withdrawal will be ready in 24 hours.',
    'Lengo hili limefungwa. Utaweza kutoa baada ya saa 24.'
  ],
  'requestWithdraw': ['Request withdrawal', 'Omba kutoa'],
  'requestMade': [
    'Request saved. You can withdraw after 24 hours.',
    'Ombi limehifadhiwa. Utaweza kutoa baada ya saa 24.'
  ],
  'emergencyOverride': ['Emergency withdrawal', 'Kutoa kwa dharura'],
  'emergencyConfirm': [
    'This goal is locked. Withdraw now because of an emergency?',
    'Lengo hili limefungwa. Toa sasa kwa sababu ya dharura?'
  ],
  'withdrawNow': ['Withdraw now', 'Toa sasa'],
  'tooMuch': ['You can withdraw up to {a}', 'Unaweza kutoa hadi {a}'],
  'withdrawRequest': ['Withdrawal request', 'Ombi la kutoa'],
  'requestReady': ['Ready: you can withdraw now.', 'Tayari: unaweza kutoa sasa.'],
  'requestWait': ['Ready in {a}', 'Itakuwa tayari baada ya {a}'],
  'cancelRequest': ['Cancel request', 'Futa ombi'],
  'savedMsg': ['Saved {a}', 'Umeweka {a}'],
  'savedExtraMsg': ['Saved {a}. Extra this period: {b}', 'Umeweka {a}. Ziada kipindi hiki: {b}'],
  'spentMsg': ['Recorded spending of {a}', 'Matumizi ya {a} yamerekodiwa'],
  'incomeMsg': ['Recorded income of {a}', 'Mapato ya {a} yamerekodiwa'],
  'withdrawMsg': ['Withdrew {a}', 'Umetoa {a}'],
  'limitOver': [
    'You have passed your {c} limit: {a} of {b}',
    'Umepita mpaka wa {c}: {a} kati ya {b}'
  ],
  'limitNear': [
    'Careful: {c} is at {a} of {b} this month',
    'Tahadhari: {c} imefika {a} kati ya {b} mwezi huu'
  ],
  'limitStatus': ['This month: {a} of {b}', 'Mwezi huu: {a} kati ya {b}'],
  'saveFirst': ['Save first', 'Weka akiba kwanza'],
  'saveFirstAsk': [
    'Save {p}% of this income ({a}) to {g} now?',
    'Weka {p}% ya mapato haya ({a}) kwenye {g} sasa?'
  ],
  'saveNow': ['Save now', 'Weka sasa'],
  'saveFirstHelp': [
    'When you log income, the app suggests saving this share first.',
    'Ukiingiza mapato, programu itapendekeza kuweka sehemu hii kwanza.'
  ],

  // ---- entry labels ----
  'withdrawal': ['Withdrawal', 'Utoaji'],
  'income': ['Income', 'Mapato'],
  'repayment': ['Repayment', 'Marejesho'],
  'loan': ['Loan', 'Mkopo'],
  'cat_food': ['Food', 'Chakula'],
  'cat_transport': ['Transport', 'Usafiri'],
  'cat_airtime': ['Airtime & data', 'Vocha na bando'],
  'cat_bills': ['Bills', 'Bili'],
  'cat_family': ['Family', 'Familia'],
  'cat_other': ['Other', 'Mengineyo'],
  'src_salary': ['Salary', 'Mshahara'],
  'src_business': ['Business', 'Biashara'],
  'src_gift': ['Gift', 'Zawadi'],
  'src_other': ['Other', 'Mengineyo'],
  'why_emergency': ['Emergency', 'Dharura'],
  'why_planned': ['Planned use', 'Matumizi yaliyopangwa'],
  'why_goalReached': ['Goal reached', 'Lengo limefikiwa'],
  'why_other': ['Other', 'Mengineyo'],

  // ---- history ----
  'periodsTab': ['Days / periods', 'Siku / vipindi'],
  'entries': ['Entries', 'Kumbukumbu'],
  'deleteEntry': ['Delete this entry?', 'Futa kumbukumbu hii?'],
  'filter_all': ['All', 'Zote'],
  'filter_saving': ['Savings', 'Akiba'],
  'filter_spending': ['Spending', 'Matumizi'],
  'filter_withdrawal': ['Withdrawals', 'Utoaji'],
  'filter_income': ['Income', 'Mapato'],
  'statusAbove': ['Above', 'Juu ya lengo'],
  'statusOn': ['On target', 'Kwenye lengo'],
  'statusShort': ['Short', 'Pungufu'],
  'statusMissed': ['Missed', 'Hukuweka'],
  'statusPending': ['In progress', 'Inaendelea'],
  'statusDone': ['Done', 'Imekamilika'],

  // ---- insights ----
  'thisMonth': ['This month', 'Mwezi huu'],
  'thisWeek': ['Last 7 days', 'Siku 7 zilizopita'],
  'legendIncome': ['Income', 'Mapato'],
  'legendSaved': ['Saved', 'Akiba'],
  'legendSpent': ['Spent', 'Matumizi'],
  'legendWithdrawn': ['Withdrawn', 'Zilizotolewa'],
  'netSaved': ['Net saved', 'Akiba halisi'],
  'savingRate': ['Share of income saved', 'Sehemu ya mapato iliyowekwa'],
  'topSpendingLine': ['Top spending this week: {c} ({a})', 'Matumizi makubwa wiki hii: {c} ({a})'],
  'limitsMonth': ['Spending limits this month', 'Mipaka ya matumizi mwezi huu'],
  'limitsHelp': [
    'Tap a category to set or change its monthly limit.',
    'Gusa aina ya matumizi kuweka au kubadilisha mpaka wake wa mwezi.'
  ],
  'limitFor': ['Monthly limit for', 'Mpaka wa mwezi kwa'],
  'setLimit': ['set limit', 'weka mpaka'],
  'limit': ['Limit', 'Mpaka'],
  'byLocation': ['Where your savings are', 'Akiba yako iko wapi'],
  'monthlyReport': ['Monthly report (PDF)', 'Ripoti ya mwezi (PDF)'],
  'reportHelp': [
    'Create a PDF to share on WhatsApp, email or print.',
    'Tengeneza PDF ya kutuma WhatsApp, barua pepe au kuchapisha.'
  ],
  'reportFailed': ['Could not create the report', 'Imeshindwa kutengeneza ripoti'],
  'reportTitle': ['Monthly report', 'Ripoti ya mwezi'],
  'reportSummary': ['Summary', 'Muhtasari'],
  'reportMade': ['Created on', 'Imetengenezwa tarehe'],
  'spendingByCatShort': ['Spending by category', 'Matumizi kwa aina'],

  // ---- rewards ----
  'badges': ['Badges', 'Beji'],
  'badge_firstSave': ['First saving', 'Akiba ya kwanza'],
  'badge_streak7': ['7 in a row', 'Mfululizo 7'],
  'badge_streak30': ['30 in a row', 'Mfululizo 30'],
  'badge_saved100k': ['TZS 100,000 saved', 'TZS 100,000 zimewekwa'],
  'badge_saved1m': ['TZS 1 million saved', 'TZS milioni 1 zimewekwa'],
  'badge_goalDone': ['Goal reached', 'Lengo limefikiwa'],
  'badge_noSpend7': ['7 days no spending', 'Siku 7 bila matumizi'],
  'badge_loanRepaid': ['Loan repaid', 'Mkopo umerudishwa'],
  'badge_challengeDone': ['Challenge won', 'Changamoto imeshindwa'],
  'challenges': ['Challenges', 'Changamoto'],
  'ch_week52': ['52-week challenge', 'Changamoto ya wiki 52'],
  'chd_week52': [
    'Week 1 save TZS 1,000, week 2 TZS 2,000, and so on. After 52 weeks you have TZS 1,378,000.',
    'Wiki ya 1 weka TZS 1,000, wiki ya 2 TZS 2,000, na kuendelea. Baada ya wiki 52 utakuwa na TZS 1,378,000.'
  ],
  'w52Line': [
    'Week {w}: save {a} this week (saved {b}). Total so far: {t}',
    'Wiki {w}: weka {a} wiki hii (umeweka {b}). Jumla hadi sasa: {t}'
  ],
  'ch_nospend': ['No-spend days', 'Siku bila matumizi'],
  'chd_nospend': [
    'Have 10 days without any spending in the next 30 days.',
    'Kuwa na siku 10 bila matumizi yoyote ndani ya siku 30 zijazo.'
  ],
  'nospendLine': ['{n} of 10 no-spend days', 'Siku {n} kati ya 10 bila matumizi'],
  'ch_streak30': ['30-day saving streak', 'Mfululizo wa siku 30'],
  'chd_streak30': [
    'Save something every day for 30 days in a row.',
    'Weka akiba kila siku kwa siku 30 mfululizo.'
  ],
  'streak30Line': ['Best run: {n} of 30 days', 'Mfululizo bora: siku {n} kati ya 30'],
  'startChallenge': ['Start', 'Anza'],
  'started': ['Started', 'Ilianza'],
  'challengeDone': ['Completed! Well done.', 'Imekamilika! Hongera.'],
  'challengeEnded': ['Time is up', 'Muda umekwisha'],
  'stopChallengeAsk': ['Stop this challenge?', 'Acha changamoto hii?'],

  // ---- settings ----
  'reminder': ['Reminder', 'Kikumbusho'],
  'dailyReminder': ['Daily reminder', 'Kikumbusho cha kila siku'],
  'reminderHelp': ['A notification reminding you to save', 'Taarifa ya kukukumbusha kuweka akiba'],
  'reminderTime': ['Time', 'Saa'],
  'reminderFailed': ['Could not set the reminder', 'Imeshindwa kuweka kikumbusho'],
  'reminderTitle': ['Akiba', 'Akiba'],
  'reminderBody': [
    "Have you saved today? Log it now and keep your streak.",
    'Umeweka akiba leo? Iingize sasa uendeleze mfululizo wako.'
  ],
  'reminderChannel': ['Daily reminder', 'Kikumbusho cha kila siku'],
  'security': ['Security', 'Usalama'],
  'pinLock': ['PIN lock', 'Funga kwa PIN'],
  'pinLockHelp': ['Ask for a PIN when opening the app', 'Uliza PIN unapofungua programu'],
  'fingerprint': ['Unlock with fingerprint', 'Fungua kwa alama ya kidole'],
  'newPin': ['Choose a PIN', 'Chagua PIN'],
  'repeatPin': ['Enter the PIN again', 'Ingiza PIN tena'],
  'pinHelp': ['4 to 6 digits', 'Tarakimu 4 hadi 6'],
  'pinTooShort': ['The PIN must have at least 4 digits', 'PIN lazima iwe na tarakimu 4 au zaidi'],
  'pinMismatch': ['The PINs did not match', 'PIN hazilingani'],
  'pinSet': ['PIN lock is on', 'Kufunga kwa PIN kumewashwa'],
  'enterPin': ['Enter your PIN', 'Ingiza PIN yako'],
  'wrongPin': ['Wrong PIN', 'PIN si sahihi'],
  'unlock': ['Unlock', 'Fungua'],
  'bioReason': ['Unlock Akiba', 'Fungua Akiba'],
  'locations': ['Savings locations', 'Mahali pa akiba'],
  'addLocation': ['Add location', 'Ongeza mahali'],
  'backup': ['Backup', 'Nakala ya data'],
  'copyBackup': ['Copy backup', 'Nakili nakala'],
  'copyBackupSub': [
    'Paste it somewhere safe, e.g. WhatsApp to yourself',
    'Ibandike mahali salama, mfano WhatsApp kwako mwenyewe'
  ],
  'backupCopied': ['Backup copied', 'Nakala imenakiliwa'],
  'restore': ['Restore from backup', 'Rejesha kutoka nakala'],
  'pasteBackup': ['Paste your backup text', 'Bandika maandishi ya nakala'],
  'restored': ['Data restored', 'Data imerejeshwa'],
  'restoreFailed': ['That backup text is not valid', 'Maandishi hayo si nakala sahihi'],
  'resetAll': ['Delete all data', 'Futa data yote'],
  'resetConfirm': [
    'This deletes all goals and entries on this phone. Continue?',
    'Hii itafuta malengo na kumbukumbu zote kwenye simu hii. Endelea?'
  ],
  // ---- home v3 ----
  'totalBalance': ['Total balance', 'Jumla ya akiba'],
  'showBalance': ['Show balance', 'Onyesha salio'],
  'hideBalance': ['Hide balance', 'Ficha salio'],
  'byGoal': ['By goal', 'Kwa lengo'],
  'savedShort': ['saved', 'imewekwa'],
  'daysShort': ['days', 'siku'],
  'thisWeekShort': ['This week', 'Wiki hii'],
  'thisMonthShort': ['This month', 'Mwezi huu'],
  'otherAmount': ['Other amount', 'Kiasi kingine'],
  'done': ['Done', 'Imekamilika'],
  'extraShort': ['extra', 'ziada'],
  'left': ['left', 'imebaki'],
  'last7': ['Last 7 days', 'Siku 7 zilizopita'],
  'ahead': ['Ahead', 'Mbele'],
  'behindShort': ['Behind', 'Nyuma'],
  'finish': ['Finish', 'Kumaliza'],
  'extraShortLabel': ['Extra saved', 'Ziada'],
  'undo': ['Undo', 'Rudisha'],
  'streakInfo': [
    'How many days (or weeks or months) in a row you have hit your target.',
    'Idadi ya siku (au wiki au miezi) mfululizo uliyofikia lengo lako.'
  ],
  'paceInfo': [
    'Time used: {a}. Money saved: {b}. Keep money ahead of time to finish on schedule.',
    'Muda uliotumika: {a}. Pesa zilizowekwa: {b}. Weka pesa mbele ya muda ili umalize kwa wakati.'
  ],
  'finishInfo': [
    'At your recent pace you finish on {a}. Your deadline is {b}.',
    'Kwa kasi yako ya karibuni utamaliza tarehe {a}. Tarehe yako ya mwisho ni {b}.'
  ],
  'extraInfo': [
    'Saved above your targets: {a}. In the emergency buffer: {b}.',
    'Ulichoweka juu ya malengo: {a}. Kwenye akiba ya dharura: {b}.'
  ],
  'requestBanner': ['Withdrawal {a} · {s}', 'Kutoa {a} · {s}'],
  'readyWord': ['ready', 'tayari'],
  'waitWord': ['waiting 24h', 'inasubiri saa 24'],
  'shortBanner': ['Short {a} last period', 'Pungufu {a} kipindi kilichopita'],
  'oweBanner': ['Owe {a} · {g}', 'Deni {a} · {g}'],
  'limitBanner': ['{c} at {p}% of limit', '{c} imefika {p}% ya mpaka'],
  // ---- v4 ----
  'name': ['Name', 'Jina'],
  'phone': ['Phone', 'Simu'],
  'email': ['Email', 'Barua pepe'],
  'city': ['Town or city', 'Mji'],
  'motto': ['My saving motto', 'Kauli mbiu yangu'],
  'myProfile': ['My profile', 'Wasifu wangu'],
  'profilePrivate': [
    'Your profile stays on this phone and is included in your backup.',
    'Wasifu wako unabaki kwenye simu hii na unajumuishwa kwenye nakala.'
  ],
  'unsavedAsk': ['You have unsaved changes. Leave without saving?', 'Una mabadiliko ambayo hayajahifadhiwa. Toka bila kuhifadhi?'],
  'discard': ['Leave', 'Toka'],
  'settingsSaved': ['Changes saved', 'Mabadiliko yamehifadhiwa'],
  'appearance': ['Appearance', 'Mwonekano'],
  'colorTheme': ['Colour', 'Rangi'],
  'mode_system': ['System', 'Mfumo'],
  'mode_light': ['Light', 'Mwanga'],
  'mode_dark': ['Dark', 'Giza'],
  'mode_black': ['Pure black', 'Nyeusi kabisa'],
  'color_green': ['Green', 'Kijani'],
  'color_blue': ['Blue', 'Bluu'],
  'color_purple': ['Purple', 'Zambarau'],
  'color_gold': ['Gold', 'Dhahabu'],
  'color_coral': ['Coral', 'Matumbawe'],
  'securityNow': [
    'Security changes apply as soon as you confirm them.',
    'Mabadiliko ya usalama yanatumika mara unapoyathibitisha.'
  ],
  'pinOffAsk': ['Turn off the PIN lock?', 'Zima kufunga kwa PIN?'],
  'shareBackup': ['Share backup file', 'Tuma faili ya nakala'],
  'shareBackupSub': [
    'Save it to Google Drive, WhatsApp or email',
    'Ihifadhi Google Drive, WhatsApp au barua pepe'
  ],
  'restoreFile': ['Restore from backup file', 'Rejesha kutoka faili ya nakala'],
  'restoreAsk': [
    'This replaces the data on this phone with the backup. Continue?',
    'Hii itabadilisha data ya simu hii kwa nakala. Endelea?'
  ],
  'backupFailed': ['Could not create the backup file', 'Imeshindwa kutengeneza faili ya nakala'],
  'wallet': ['Wallet', 'Pochi'],
  'walletHelp': [
    'Everyday money: income minus spending and savings, plus withdrawals.',
    'Pesa za kila siku: mapato toa matumizi na akiba, ongeza ulizotoa.'
  ],
  'planTab': ['Plans', 'Mipango'],
  'edit': ['Edit', 'Hariri'],
  'splitTitle': ['Auto-split savings', 'Gawanya akiba'],
  'splitHelp': [
    'When you choose "Split" while saving, the amount is shared across goals by these percentages.',
    'Ukichagua "Gawanya" unapoweka akiba, kiasi kinagawanywa kwa malengo kwa asilimia hizi.'
  ],
  'splitEmpty': ['Not set up yet', 'Bado haijawekwa'],
  'splitMust100': ['The total must be exactly 100%', 'Jumla lazima iwe 100% kamili'],
  'splitChip': ['Split', 'Gawanya'],
  'plansTitle': ['Recurring savings', 'Akiba za kurudia'],
  'plansEmpty': ['e.g. save 20,000 every Friday', 'mfano weka 20,000 kila Ijumaa'],
  'newPlan': ['New recurring saving', 'Akiba mpya ya kurudia'],
  'editPlan': ['Edit recurring saving', 'Hariri akiba ya kurudia'],
  'howOften': ['How often', 'Mara ngapi'],
  'dayOfMonth': ['Day of the month', 'Tarehe ya mwezi'],
  'planNotif': ['Time to save {a} to {g}', 'Ni wakati wa kuweka {a} kwenye {g}'],
  'planBanner': ['Plan: save {a} · {g}', 'Mpango: weka {a} · {g}'],
  'billsTitle': ['Bills', 'Bili'],
  'billsEmpty': ['Add rent, school fees, LUKU...', 'Ongeza kodi, ada ya shule, LUKU...'],
  'newBill': ['New bill', 'Bili mpya'],
  'editBill': ['Edit bill', 'Hariri bili'],
  'billName': ['Bill name', 'Jina la bili'],
  'dueEveryMonth': ['Due every month on day', 'Inalipwa kila mwezi tarehe'],
  'billReminderHelp': [
    'You get a reminder two days before.',
    'Utapata kikumbusho siku mbili kabla.'
  ],
  'billNotif': ['{n} ({a}) is due on the {d}th', '{n} ({a}) inalipwa tarehe {d}'],
  'billBanner': ['{n} {a} · {s}', '{n} {a} · {s}'],
  'markPaid': ['Mark paid', 'Imelipwa'],
  'paidThisMonth': ['Paid this month', 'Imelipwa mwezi huu'],
  'overdue': ['Overdue', 'Imechelewa'],
  'dueInDays': ['Due in {n} days', 'Inalipwa baada ya siku {n}'],
  'debtsTitle': ['Money owed', 'Madeni'],
  'debtsEmpty': ['Track who owes you and whom you owe', 'Fuatilia wanaokudai na unaowadai'],
  'newDebt': ['New record', 'Rekodi mpya'],
  'owedToMe': ['Owed to me', 'Ninadai'],
  'iOwe': ['I owe', 'Ninadaiwa'],
  'person': ['Person', 'Mtu'],
  'dueOptional': ['Due date (optional)', 'Tarehe ya kulipa (si lazima)'],
  'recordPayment': ['Record payment', 'Rekodi malipo'],
  'debtProgress': ['Paid {a} of {b}', 'Imelipwa {a} kati ya {b}'],
  'settled': ['Settled', 'Imelipwa yote'],
  'debtBannerIn': ['{p} owes you {a}', '{p} anakudai {a}'],
  'debtBannerOut': ['You owe {p} {a}', 'Unamdai {p} {a}'],
  'whatIf': ['What if I save...', 'Je, nikiweka...'],
  'useAmount': ['Use this amount', 'Tumia kiasi hiki'],
  'afterDeadline': ['After your deadline', 'Baada ya tarehe yako ya mwisho'],
  'beforeDeadline': ['On time', 'Kwa wakati'],
  'calMet': ['Target met', 'Lengo limefikiwa'],
  'calShort': ['Short', 'Pungufu'],
  'calMissed': ['Missed', 'Hukuweka'],
  'calDay': ['{d}: saved {a}, spent {b}', '{d}: umeweka {a}, umetumia {b}'],
  'tipsTitle': ['Tips for you', 'Ushauri kwako'],
  'tipCatUp': ['{c} spending is up {p}% this week', 'Matumizi ya {c} yamepanda {p}% wiki hii'],
  'tipCatDown': ['{c} spending is down {p}% this week. Nice!', 'Matumizi ya {c} yameshuka {p}% wiki hii. Vizuri!'],
  'tipBestDay': ['You save the most on {d}s', 'Unaweka akiba zaidi siku ya {d}'],
  'tipRate': ['You have saved {p}% of this month\'s income', 'Umeweka {p}% ya mapato ya mwezi huu'],
  'tipStreak': ['{n} in a row. Keep the streak going!', 'Mfululizo wa {n}. Endeleza!'],
  'widgetDone': ['Today done ✓', 'Leo imekamilika ✓'],
  'widgetLeft': ['{a} left today', '{a} imebaki leo'],
};

String t(String key) {
  final v = _s[key];
  if (v == null) return key;
  return currentLang == 'sw' ? v[1] : v[0];
}

String tf(String key, Map<String, String> params) {
  var s = t(key);
  params.forEach((k, v) {
    s = s.replaceAll('{$k}', v);
  });
  return s;
}

const List<String> _monthsEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const List<String> _monthsSw = [
  'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
  'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
];
const List<String> _monthsLongEn = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December'
];
const List<String> _monthsLongSw = [
  'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni', 'Julai',
  'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
];
const List<String> _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _daysSw = ['Jtt', 'Jnn', 'Jtn', 'Alh', 'Iju', 'Jms', 'Jpl'];

String monthShort(int m) => (currentLang == 'sw' ? _monthsSw : _monthsEn)[m - 1];
String monthLong(int m) =>
    (currentLang == 'sw' ? _monthsLongSw : _monthsLongEn)[m - 1];
const List<String> _daysLongEn = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const List<String> _daysLongSw = [
  'Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'
];

String weekdayLong(int weekday) =>
    (currentLang == 'sw' ? _daysLongSw : _daysLongEn)[weekday - 1];

String weekdayShort(int weekday) =>
    (currentLang == 'sw' ? _daysSw : _daysEn)[weekday - 1];
