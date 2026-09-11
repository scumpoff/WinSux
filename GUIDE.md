# WinSux — Guide d'utilisation
Par ELIAS

Script d'optimisation Windows tout-en-un : installe les outils de base, allège le système, réinstalle **automatiquement** le pilote NVIDIA proprement, applique des tweaks de performance CPU/GPU/réseau, et nettoie Windows.

## Prérequis
- Windows 10/11 (Home/Pro/LTSC/IoT/Server)
- Connexion Internet
- **GPU NVIDIA** pour la partie pilote (le reste s'applique quand même sans NVIDIA)
- Une fresh install de Windows recommandée (le script désactive Defender, UAC, BitLocker et d'autres protections système — voir avertissements en bas)

## Contenu du dossier
Copie **tout le dossier tel quel** (ne pas séparer `WinSux.ps1` de `Temp/`) :
```
WinSux-main/
├── WinSux.ps1           <- script principal, à lancer
├── AllowScripts.cmd     <- à lancer d'abord si PowerShell bloque les scripts
├── LICENSE
├── README.md
├── GUIDE.md             <- ce fichier
└── Temp/
    ├── stepone.ps1      <- étape 1 (safe mode)
    ├── steptwo.ps1      <- étape 2 (boot normal)
    ├── 7zip.exe, ddu.exe, directx.exe, inspector.exe
    ├── vcredist*.exe (C++ redistributables)
    └── reg.reg, settimerresolutionservice.cs, start2.txt
```

## Comment copier sur un autre PC
- Clé USB, disque externe, ou partage réseau : copie le dossier `WinSux-main` en entier.
- Rien à installer ni télécharger en plus, tout est déjà dans `Temp/`.

## Étapes d'utilisation

### 0. (Si besoin) Débloquer l'exécution des scripts
Si Windows refuse de lancer `WinSux.ps1`, double-clique **`AllowScripts.cmd`** d'abord, choisis l'option **1**. Il autorise l'exécution des scripts PowerShell et débloque tous les fichiers du dossier.

### 1. Lancer le script principal
Double-clique **`WinSux.ps1`** → "Exécuter avec PowerShell". Une popup UAC apparaît, accepte-la (le script s'auto-élève en administrateur).

### 2. Phase 1 — automatique
Le script :
- mémorise le nom exact du GPU NVIDIA (avant que DDU efface le pilote)
- copie les fichiers de `Temp/` vers `C:\Windows\Temp`
- installe 7-Zip, les runtimes C++, DirectX
- extrait DDU (Display Driver Uninstaller)
- programme `stepone.ps1` et `steptwo.ps1` pour s'exécuter automatiquement au prochain démarrage
- active le démarrage en mode sans échec
- **redémarre tout seul** après 5 secondes

### 3. Phase 2 — mode sans échec, automatique
`stepone.ps1` se lance automatiquement :
- désactive Windows Defender, UAC, protections diverses
- désinstalle les pilotes GPU/audio existants (NVIDIA, AMD, Intel, Realtek) via DDU
- **redémarre à nouveau tout seul**

### 4. Phase 3 — boot normal, **entièrement automatique**
`steptwo.ps1` se lance automatiquement :
- suppression des applications heritees (OneDrive, brlapi, GameInput, Remote Desktop, ancien Snipping Tool)
- **téléchargement et installation automatiques du pilote NVIDIA** : identification du modèle, appel à l'API NVIDIA, téléchargement avec barre de progression, allègement du paquet, installation silencieuse
  - *aucune action requise* — une sélection manuelle n'est proposée qu'en dernier recours si les serveurs NVIDIA sont injoignables
- profil NVIDIA Profile Inspector orienté FPS bruts : power management max perf, V-Sync forcé off, file de rendu limitée à 1 image, cache de shaders illimité, optimisations de filtrage actives, LOD bias clampé. **Ni G-Sync ni Resizable BAR** (voir plus bas)
- **installation silencieuse de MSI Afterburner** + limite de puissance portée au maximum de la carte et cible thermique à 83 °C via `nvidia-smi`
- optimisations : GameDVR off, HAGS on, MPO off, Nagle off, SysMain off, MSI mode GPU, DPC par cœur
- optimisations CPU : pas de core parking, EPP performance, ramp-up « rocket », kernel non pagé, NTFS accéléré, prefetcher off, mitigations Spectre/Meltdown désactivées
- plan d'alimentation Ultimate Performance, résolution du minuteur système
- **outils d'entretien** : taux de rafraîchissement maximum forcé sur tous les écrans, tâche d'entretien automatique au démarrage, et un dossier **Entretien PC** sur le bureau avec 15 raccourcis
- nettoyage disque + point de restauration
- **rapport de vérification** : 27 contrôles relus depuis l'état réel du système, affichés OK/ÉCHEC et enregistrés dans `C:\ProgramData\Optimisation\rapport.txt`
- **redémarrage final automatique** (20 s, le temps de lire le rapport)

## Politique thermique
Le pack cherche la performance **sous charge**, pas des fréquences bloquées au maximum en permanence :
- **C-states laissés actifs**, et **état minimal du processeur adapté au châssis** : le script détecte automatiquement le type de machine.
  - **Portable → 5 %.** Épingler à 100 % ajoute 15-25 °C au repos dans un châssis fin : le package part chaud, atteint sa limite thermique plus tôt et boost *moins* loin sous charge réelle. On y perd des FPS au lieu d'en gagner.
  - **PC fixe → 100 %.** Une tour a la marge de refroidissement pour absorber cette chaleur, donc supprimer les états basse consommation est un gain net : plus aucune latence de montée en fréquence.
- La réactivité vient de `EPP=0` + montée en fréquence « rocket », qui répondent en microsecondes.
- La **limite de puissance GPU est portée au maximum de la carte** et la cible thermique fixée à **83 °C** via `nvidia-smi`. Ce réglage ne survit pas à un redémarrage — le mode persistance de `nvidia-smi` n'existe pas sous Windows, et le profil Afterburner ne transporte que des réglages d'interface. Une tâche planifiée **au démarrage uniquement** le réapplique donc à chaque boot. Elle ne rejoue plus le réglage toutes les 15 minutes : c'était cette répétition qui entrait en conflit avec Afterburner, pas le fait de restaurer la valeur une fois au boot.
- Le profil Inspector règle **Power Management sur « Prefer Maximum Performance »** : les fréquences GPU ne fluctuent plus en cours de partie, ce qui supprime une source classique de micro-saccades.
  - Sur un **portable Optimus** (écran piloté par l'iGPU, cas le plus courant), ce réglage ne coûte rien au repos : la carte NVIDIA est purement et simplement éteinte quand aucune application 3D ne tourne.
  - Sur un **PC fixe**, où la carte pilote l'écran en permanence, il maintient effectivement les fréquences hautes sur le bureau (environ 20-30 W). Pour l'annuler : Inspector → `Power Management - Mode` → *Adaptive*.

## Deux arbitrages GPU à connaître

**Resizable BAR et G-Sync : volontairement absents du profil.**
- *rBAR* : ses identifiants numériques venaient de profils communautaires et non de NVIDIA, et l'entrée « Size Limit » utilisait un type de valeur qu'Inspector refuse. L'import faisait planter l'outil — donc **tout** le profil échouait, pas seulement ces trois lignes. À activer à la main si tu y tiens : `inspector.exe`, section « 5 - Common », où l'outil valide les valeurs lui-même.
- *G-Sync* : retiré. Sans effet de toute façon sur un portable Optimus, où l'écran est piloté par l'iGPU et non par la carte NVIDIA.

**Ultra Low Latency désactivé.** Ce mode limite la file de rendu pour réduire la latence, au prix de quelques images par seconde quand la carte est le facteur limitant. Le pack privilégie désormais les FPS bruts.
→ *Pour revenir en arrière : Panneau de configuration NVIDIA → Gérer les paramètres 3D → Mode faible latence → **Ultra**.*

## Réglage fin du GPU — à faire une fois, à la main
Le script installe MSI Afterburner et débloque le contrôle de tension, mais **n'applique volontairement aucun offset de fréquence, de mémoire ou de tension**. Ces valeurs dépendent de l'exemplaire de puce : un profil copié d'ailleurs donne au mieux rien, au pire des écrans noirs. Voici la marche à suivre, par ordre de rendement :

1. **Undervolt par la courbe** (`Ctrl+F` dans Afterburner) — le meilleur réglage disponible. Choisis un point autour de **0,900-0,950 V**, monte-le à la fréquence que la carte atteignait à pleine tension, aplatis la courbe à droite, applique. Résultat typique : mêmes performances, 30 à 50 W et une dizaine de degrés en moins.
2. **Offset mémoire** — commence à **+500 MHz**, par paliers de 250. Attention : la GDDR6X/GDDR7 corrige ses erreurs en silence, donc au-delà du point stable tu ne verras **pas** d'artefacts, tu perdras simplement des performances. Valide toujours avec un benchmark chiffré, pas à l'œil.
3. **Offset GPU** — +150 à +250 MHz en général, gain modeste.

Valide chaque étape avec 20-30 minutes de charge réelle avant de passer à la suivante, et enregistre dans un profil Afterburner appliqué au démarrage.

## Gains réalistes
Les tweaks OS/registre donnent typiquement **1 à 4 %** en jeu. Les vrais leviers restent dans le BIOS et ne peuvent pas être automatisés par un script :
- **XMP / EXPO** sur la mémoire — souvent le plus gros gain isolé (5-15 % selon les jeux)
- **Resizable BAR / Above 4G Decoding**
- Refroidissement : une courbe de ventilation correcte vaut plus que n'importe quelle clé de registre

### 5. Terminé
Après le dernier redémarrage, le PC est prêt.

## Temps d'exécution
15-30 minutes au total, incluant 2 redémarrages automatiques. Plus aucune pause manuelle en fonctionnement normal.

## Ce qui est volontairement CONSERVÉ
Pour éviter de casser l'affichage et les applications :
- **toutes les applications et fonctionnalités UWP** — le pack n'y touche plus du tout : aucun `Remove-AppxPackage`, aucune opération DISM (`Remove-WindowsCapability`, `Disable-WindowsOptionalFeature`). Ce sont elles qui bloquaient de longues minutes.
- le **Microsoft Store**, **winget**, le **Panneau de configuration NVIDIA**
- **Microsoft Edge** — le pack n'y touche pas
- **NvContainer / NvCpl / HDAudio / PhysX** dans le pilote NVIDIA (audio HDMI/DP, panneau de configuration, vieux jeux PhysX)
- la **mise à l'échelle DPI** choisie par Windows (plus de forçage à 100 %)

## ⚠️ Avertissements importants
- **Sécurité désactivée** : Windows Defender (temps réel, cloud, tamper protection), UAC, BitLocker, SmartScreen, VBS/memory integrity sont désactivés. Le PC n'a plus de protection antivirus active. À réserver à une machine dédiée au gaming.
- **Mitigations CPU désactivées** : les protections Spectre / Meltdown / MDS sont coupées (`FeatureSettingsOverride=3`) pour récupérer quelques % de CPU. Pour revenir en arrière : supprimer `FeatureSettingsOverride` et `FeatureSettingsOverrideMask` dans `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`, puis redémarrer.
- **Irréversible en grande partie**. Le point de restauration créé à la fin ne couvre pas les changements déjà appliqués avant sa création.
- **Ne pas interrompre** les phases automatiques.
