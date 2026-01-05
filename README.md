# UseMemos

<hr>

## 安装
```bash
bash <(curl -Ls https://raw.githubusercontent.com/co2f2e/UseMemos/main/install.sh) 7000
```

## 卸载
```bash
bash <(curl -Ls https://raw.githubusercontent.com/co2f2e/UseMemos/main/uninstall.sh) 
```
## NGINX
```bash
    location / {
        proxy_pass http://127.0.0.1:7000/;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_buffering off;
    }
```
