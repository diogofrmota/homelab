# Get the Pi-hole pod name
PIHOLE_POD=$(kubectl get pods -n pihole -l app=pihole -o jsonpath='{.items[0].metadata.name}')

# Port forward from Raspberry Pi (bind to all interfaces so PC can access it)
kubectl port-forward -n pihole $PIHOLE_POD 8080:80 --address 0.0.0.0

#Access "http://[MASTER_NODE_IP]:8080/admin"

# Get the Pi-hole password from the secret
kubectl get secret -n pihole pihole-password -o jsonpath='{.data.password}' | base64 -d && echo