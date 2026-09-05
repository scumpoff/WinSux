# WinSux — Guide d'utilisation
Par ELIAS

Script d'optimisation Windows tout-en-un : installe les outils de base, débloate le système, réinstalle les pilotes GPU proprement, applique des tweaks de performance gaming, et nettoie Windows.

## Prérequis
- Windows 10/11 (Home/Pro/LTSC/IoT/Server)
- Connexion Internet
- Une fresh install de Windows recommandée (le script désactive Defender, UAC, BitLocker et d'autres protections système — voir avertissements en bas)

## Contenu du dossier
Copie **tout le dossier tel quel** (ne pas séparer `WinSux.ps1` de `Temp/`) :
```
WinSux-main/
├── WinSux.ps1          <- script principal, à lancer
├── AllowScripts.cmd     <- à lancer d'abord si PowerShell bloque les scripts
├── LICENSE
├── README.md
├── GUIDE.md             <- ce fichier
└── Temp/
    ├── stepone.ps1      <- étape 1 (safe mode)
    ├── steptwo.ps1      <- étape 2 (boot normal)
    ├── 7zip.exe, chrome.exe, ddu.exe, directx.exe, inspector.exe
    ├── vcredist*.exe (C++ redistributables)
    └── reg.reg, settimerresolutionservice.cs, start2.txt
```

## Comment copier sur un autre PC
- Clé USB, disque externe, ou partage réseau : copie le dossier `WinSux-main` en entier.
- Rien à installer ni télécharger en plus, tout est déjà dans `Temp/`.

## Étapes d'utilisation

### 0. (Si besoin) Débloquer l'exécution des scripts
Si Windows refuse de lancer `WinSux.ps1` (politique d'exécution PowerShell par défaut, ou fichiers marqués "téléchargés depuis Internet"), double-clique **`AllowScripts.cmd`** d'abord, choisis l'option **1**. Il autorise l'exécution des scripts PowerShell et débloque tous les fichiers du dossier.

### 1. Lancer le script principal
Double-clique **`WinSux.ps1`** → "Exécuter avec PowerShell" (ou clic droit dessus). Une popup UAC apparaît, accepte-la (le script s'auto-élève en administrateur).

### 2. Phase 1 — automatique
Le script :
- copie les fichiers de `Temp/` vers `C:\Windows\Temp`
- installe 7-Zip, les runtimes C++, DirectX, Google Chrome
- extrait DDU (Display Driver Uninstaller)
- programme `stepone.ps1` et `steptwo.ps1` pour s'exécuter automatiquement au prochain démarrage
- active le démarrage en mode sans échec
- **redémarre tout seul** après 5 secondes

Ne touche à rien, laisse-le redémarrer.

### 3. Phase 2 — mode sans échec, automatique
Windows redémarre en mode sans échec et `stepone.ps1` se lance automatiquement :
- désactive Windows Defender, UAC, protections diverses (nécessite le mode sans échec pour certaines clés protégées)
- désinstalle les pilotes GPU/audio existants (NVIDIA, AMD, Intel, Realtek) via DDU
- **redémarre à nouveau tout seul**

### 4. Phase 3 — boot normal, semi-manuelle
Windows redémarre normalement et `steptwo.ps1` se lance automatiquement :
- supprime Edge, les applications/fonctionnalités UWP et héritées inutiles
- **⚠️ une pause manuelle ici** : un menu texte demande de choisir ton GPU (NVIDIA / AMD / Intel / Ignorer)
  - Chrome s'ouvre sur la page des pilotes officiels → télécharge le pilote
  - reviens dans la fenêtre PowerShell, appuie sur une touche
  - une fenêtre de sélection de fichier s'ouvre → choisis le pilote téléchargé
  - le script débloate le pilote (retire GeForce Experience/telemetry/etc.), l'installe, puis applique un profil de tuning complet (NVIDIA : NVIDIA Profile Inspector avec low latency ultra, power management max perf, etc.)
- applique les optimisations gaming : GameDVR off, HAGS on, Nagle's algorithm off, SysMain off
- configure le plan d'alimentation (Ultimate Performance), la résolution du minuteur système
- nettoyage disque + création d'un point de restauration
- **redémarrage final automatique**

### 5. Terminé
Après le dernier redémarrage, le PC est prêt : debloaté, pilotes propres, tweaks gaming appliqués.

## Temps d'exécution
Compte 20-40 minutes au total (dépend surtout du téléchargement manuel du pilote GPU à l'étape 4), incluant 2 redémarrages automatiques.

## ⚠️ Avertissements importants
- **Sécurité désactivée** : Windows Defender (temps réel, cloud, tamper protection), UAC, BitLocker, SmartScreen, VBS/memory integrity sont désactivés. Le PC n'a plus de protection antivirus active. À réserver à une machine dédiée au gaming, pas pour naviguer/télécharger sans précaution.
- **Irréversible en grande partie** : certains changements (suppression d'apps, désinstallation d'Edge, debloat des pilotes) ne se défont pas facilement. Le point de restauration créé à la fin ne couvre pas les changements déjà appliqués avant sa création.
- **Ne pas interrompre** les phases automatiques (surtout pendant les redémarrages et l'exécution des scripts RunOnce).
