# VPN-IUT-BELFORT

Scripts permettant aux étudiants de l'IUT de Belfort-Montbéliard de configurer rapidement le VPN de l'Université de Franche-Comté (uFC) sur Windows et Linux.

## Contenu du projet

- **Init-VPN-Window.ps1** : Script PowerShell pour configurer le VPN sur Windows.
- **Init-VPN-Linux.sh** : Script Bash pour configurer le VPN sur les distributions Linux compatibles.

## Prérequis

### Windows
- Windows 10 ou version ultérieure.
- Droits administratifs pour exécuter le script PowerShell.

### Linux
- Distribution basée sur Debian ou Ubuntu (versions supportées : 18.04, 20.04, 22.04, 24.04).
- Droits `sudo` pour exécuter le script.

## Instructions d'installation

### Windows
1. Ouvrez PowerShell en tant qu'administrateur.
2. Exécutez le script `Init-VPN-Window.ps1` :
```powershell
.\init-VPN-Window.ps1
```
3. Suivez les instructions affichées pour configurer le VPN

### Linux
1. Exécutez le script avec sudo
```bash
sudo ./init-VPN-Linux.sh
```
2. Suivez les instructions affichées pour configurer le VPN

## Fonctionnalités
### Windows
- Création automatique d'une connexion VPN nommée "VPN UFC"
- Ajout des routes nécessaires pour accéder aux ressources de l'université

### Linux
- Installation des paquets nécessaires (NetworkManager, strongSwan, etc.).
- Configuration automatique de la MTU et des règles MSS.
- Configuration des DNS pour les domaines de l'université.
- Création automatique ou manuelle de la connexion VPN.

## Notes importantes
- L'adresse du serveur VPN est configurée par défaut sur vpn20-2.univ-fcomte.fr. Si cette adresse change, veuillez consulter le [site officiel du VPN de l'uFC](https://vpn.univ-fcomte.fr/?page_id=254).
- La MTU est configurée à 1300 pour éviter les problèmes de fragmentation.
- Les scripts Linux incluent un support spécifique pour les stations d'accueil Dell.

## Avertissement
Ces scripts sont fournis "tels quels". Veuillez les utiliser avec précaution et vérifier leur contenu avant exécution.

## Licence
Ce projet est sous licence MIT.