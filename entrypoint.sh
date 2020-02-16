#!/bin/bash

: "${SECRET_NAME?SECRET_NAME is required}"
: "${DOMAINS?DOMAINS is required}"
: "${EMAIL?EMAIL is required}"

function init_job() {
    mkdir -p /etc/letsencrypt/live/cert

    # tls.crt -> letsencrypt's fullchain.pem
    # tls.key -> letsencrypt's privkey.pem
    local secret_contents
    if secret_contents=$(kubectl get "secret/${SECRET_NAME}" -o json); then
        # The configmap exists
        local key="$(echo "${secret_contents}" |\
                    jq -r '.["data"]["tls.key"]' |\
                    base64 -d)"
        local cert="$(echo "${secret_contents}" |\
                      jq -r '.["data"]["tls.crt"]' |\
                      base64 -d)"

        if [ -n "$key" ]; then
            echo "$key" > /etc/letsencrypt/live/cert/privkey.pem
        fi

        if [ -n "$cert" ]; then
            echo "$cert" > /etc/letsencrypt/live/cert/fullchain.pem
        fi
    fi
}

function get_file_base64 {
    cat "$1" | base64 -w0
}

function update_configmap {
    local cert key
    cert=$(get_file_base64 /etc/letsencrypt/live/cert/fullchain.pem)
    key=$(get_file_base64 /etc/letsencrypt/live/cert/privkey.pem)
	cat <<-EOF | kubectl apply -f -
		apiVersion: v1
		kind: Secret
		type: kubernetes.io/tls
		metadata:
		name: "${SECRET_NAME}"
		data:
		  tls.crt: "${cert}"
		  tls.key: "${key}"
	EOF
}

function run_certbot {
    cd $HOME
    python3 -m http.server 80 &
    PID=$!

    certbot certonly \
    --webroot -w $HOME \
    -n --agree-tos \
    --email ${EMAIL} \
    --no-self-upgrade \
    --renew-with-new-domains \
    --cert-name cert \
    -d ${DOMAINS}

    kill $PID

    update_configmap
}

init_job
run_certbot
