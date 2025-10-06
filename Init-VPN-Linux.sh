#!/bin/bash
# Script d'installation et configuration du VPN uFC
# Compatible Debian 10 et Ubuntu 18.04/20.04/22.04/24.04
set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Installation du client VPN pour l'Université de Franche-Comté ===${NC}\n"

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ce script doit être exécuté avec les droits sudo${NC}"
    exit 1
fi

# Détection de la distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo -e "${RED}Impossible de détecter la distribution${NC}"
    exit 1
fi
echo -e "${YELLOW}Distribution détectée: $OS $VER${NC}\n"

# === ÉTAPE 1: Installation des paquets ===
echo -e "${GREEN}[1/6] Installation des paquets nécessaires...${NC}"
apt-get update
apt-get install -y network-manager-strongswan libstrongswan-extra-plugins libcharon-extra-plugins

# === ÉTAPE 2: Configuration de la MTU ===
echo -e "\n${GREEN}[2/6] Configuration de la MTU...${NC}"
IFUPDOWN_FILE="/etc/NetworkManager/dispatcher.d/01-ifupdown"
if [ -f "$IFUPDOWN_FILE" ]; then
    echo "Modification de $IFUPDOWN_FILE pour la MTU..."
    cp "$IFUPDOWN_FILE" "${IFUPDOWN_FILE}.backup"
    if grep -q "if \[ \"\$2\" = \"vpn-up\" \]" "$IFUPDOWN_FILE"; then
        sed -i '/if \[ "$2" = "vpn-up" \] || \[ "$2" = "vpn-down" \]; then/,/fi/ {
            /ADDRESS_FAMILIES=""/ a\    ip link set dev "$1" mtu 1300
        }' "$IFUPDOWN_FILE"
        echo "MTU configurée à 1300 dans $IFUPDOWN_FILE"
    fi
fi

# === ÉTAPE 3: Configuration MSS pour stations d'accueil Dell ===
echo -e "\n${GREEN}[3/6] Configuration du MSS (stations d'accueil Dell)...${NC}"
DISPATCHER_FILE="/etc/NetworkManager/dispatcher.d/00-local"
cat > "$DISPATCHER_FILE" << 'EOF'
#!/bin/sh
set -e
DEV=$1
ACTION=$2
mss_rule() {
    iptables -t mangle "$1" POSTROUTING -o "$DEV" \
        -m policy --pol ipsec --dir out \
        -p tcp -m tcp --tcp-flags SYN,RST SYN \
        -j TCPMSS --clamp-mss-to-pmtu
}
case "$ACTION" in
    vpn-up)
        mss_rule -C > /dev/null 2>&1 || mss_rule -A
        ;;
    vpn-down)
        mss_rule -D
        ;;
esac
EOF
chmod +x "$DISPATCHER_FILE"
echo "Script MSS créé: $DISPATCHER_FILE"

# === ÉTAPE 4: Configuration DNS ===
echo -e "\n${GREEN}[4/6] Configuration DNS...${NC}"
UBUNTU_24_OR_LATER=false
if [[ "$OS" == *"Ubuntu"* ]] && [ "${VER%%.*}" -ge 24 ]; then
    UBUNTU_24_OR_LATER=true
fi
if [ "$UBUNTU_24_OR_LATER" = true ]; then
    echo "Ubuntu 24+ détecté - Configuration DNS automatique via systemd-resolved"
    systemctl enable systemd-resolved
    systemctl start systemd-resolved
else
    echo "Configuration DNS avec dnsmasq..."
    systemctl stop systemd-resolved 2>/dev/null || true
    systemctl disable systemd-resolved 2>/dev/null || true
    NM_CONF="/etc/NetworkManager/NetworkManager.conf"
    if ! grep -q "dns=dnsmasq" "$NM_CONF"; then
        sed -i '/\[main\]/a dns=dnsmasq' "$NM_CONF"
    fi
    mkdir -p /etc/NetworkManager/dnsmasq.d
    cat > /etc/NetworkManager/dnsmasq.d/dns-uFC-uMLP.conf << 'EOF'
server=/univ-fcomte.fr/194.57.91.200
server=/univ-fcomte.fr/194.57.91.201
EOF
    cat > /etc/NetworkManager/dnsmasq.d/00-use-dns-google.conf << 'EOF'
server=8.8.8.8
server=8.8.4.4
EOF
    rm -f /etc/resolv.conf
    echo "Configuration DNS dnsmasq terminée"
fi
systemctl restart NetworkManager

# === ÉTAPE 5: Choix de la création de la connexion VPN ===
echo -e "\n${GREEN}[5/6] Création de la connexion VPN${NC}"
echo -e "${YELLOW}Comment souhaitez-vous créer la connexion VPN ?${NC}"
echo "1) Création automatique (recommandé)"
echo "2) Création manuelle (instructions affichées)"
read -p "Choisissez une option (1 ou 2) : " VPN_CHOICE

case "$VPN_CHOICE" in
    1)
        # Création automatique
        echo -e "\n${GREEN}Création automatique de la connexion VPN...${NC}"
        read -p "Entrez votre identifiant uFC : " UFC_USERNAME
        read -s -p "Entrez votre mot de passe uFC : " UFC_PASSWORD
        echo ""

        # Désactive temporairement l'historique pour éviter de stocker le mot de passe
        set +o history
        nmcli connection add type vpn vpn-type strongswan con-name "uFC-VPN" ifname -- \
            vpn.data "address = vpn20-2.univ-fcomte.fr, \
                      certificate = , \
                      method = eap, \
                      proposal = no, \
                      virtual = yes, \
                      encap = yes, \
                      ipcomp = no, \
                      username = $UFC_USERNAME, \
                      password-flags = 0" \
            vpn.secrets "password = $UFC_PASSWORD"

        nmcli connection modify "uFC-VPN" vpn.data "request_inner_ip = yes, enforce_udp = yes"
        set -o history

        echo -e "${GREEN}Connexion VPN créée avec succès !${NC}"
        echo "Vous pouvez l'activer depuis le menu réseau ou avec la commande :"
        echo -e "${YELLOW}nmcli connection up uFC-VPN${NC}"
        ;;
    2)
        # Instructions pour la création manuelle
        echo -e "\n${YELLOW}=== Instructions pour créer la connexion VPN manuellement ===${NC}"
        echo "1. Ouvrez 'Paramètres' → 'Réseau'"
        echo "2. Cliquez sur le '+' à côté de VPN"
        echo "3. Sélectionnez 'IPsec/IKEv2 (strongswan)'"
        echo "4. Renseignez les champs suivants :"
        echo "   - Adresse : vpn20-2.univ-fcomte.fr"
        echo "   - Identifiant : <votre identifiant uFC>"
        echo "   - Mot de passe : <votre mot de passe uFC>"
        echo "   - Certificat : laisser vide"
        echo "5. Dans les options avancées, cochez :"
        echo "   - [x] Request an inner IP address"
        echo "   - [x] Enforce UDP encapsulation"
        ;;
    *)
        echo -e "${RED}Option invalide. Aucune connexion VPN créée.${NC}"
        ;;
esac

# === ÉTAPE 6: Fin du script ===
echo -e "\n${GREEN}[6/6] Installation terminée avec succès!${NC}"
echo -e "${YELLOW}Notes importantes:${NC}"
echo "  - La MTU a été configurée à 1300"
echo "  - Les DNS de l'uFC seront utilisés automatiquement"
echo "  - Le support des stations d'accueil Dell a été ajouté"
echo "  - L'adresse du serveur VPN est au moment de la création du script: vpn20-2.univ-fcomte.fr (elle peut changer, faites attention)"
echo "  - Si l'adresse vient à changer, veuillez vous rendre sur le lien suivant: https://vpn.univ-fcomte.fr/?page_id=254"
