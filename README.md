# AOSP 10 Docker Build Environment

Environment build Android 10 (Q) berbasis Docker dengan Ubuntu 18.04, untuk host modern seperti Fedora 44 yang toolchain-nya terlalu baru untuk source Android 10.

## Fitur

- Base image Ubuntu 18.04, base yang direkomendasikan AOSP untuk Android 10
- Paket build lengkap: Python 2 dan 3, OpenJDK 8, ccache, lib32, `repo`, dan lainnya
- User di dalam container memakai UID/GID yang sama dengan host, sehingga file hasil build tidak jadi milik root
- ccache persisten di host
- `out/` berada di dalam tree source
- Kompatibel dengan SELinux (Fedora)

## Struktur

```
.
├── Dockerfile
├── docker-compose.yml
├── .env
└── README.md
```

## Prasyarat

- Docker Engine dengan plugin Compose (`docker compose`)
- RAM 16 GB atau lebih (tambahkan swap/zram jika kurang)
- Ruang disk lega untuk source, `out/`, dan ccache

Instalasi di Fedora:

```bash
sudo dnf install -y moby-engine docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # lalu logout dan login ulang
```

## Konfigurasi

Edit `.env`:

| Variabel | Default | Keterangan |
|---|---|---|
| `USER_ID` | `1000` | UID user host (`id -u`) |
| `GROUP_ID` | `1000` | GID user host (`id -g`) |
| `BUILD_USERNAME` | `aepranata` | Username yang tertulis di build |
| `BUILD_HOSTNAME` | `ae-server` | Hostname yang tertulis di build |
| `SRC_DIR` | `!/aosp10` | Lokasi source AOSP di host |
| `CCACHE_DIR_HOST` | `~/.ccache-aosp10` | Lokasi cache ccache di host |

Pastikan `USER_ID` dan `GROUP_ID` sesuai dengan user host sebelum build image.

## Pemakaian

Build image (sekali saja, atau saat Dockerfile berubah):

```bash
docker compose build
```

Masuk ke shell build:

```bash
docker compose run --rm aosp10
```

Di dalam container, source ada di `/src`:

```bash
source build/envsetup.sh
lunch <target>
m -j$(nproc)
```

Atau jalankan langsung satu perintah:

```bash
docker compose run --rm aosp10 /bin/bash -lc \
  'source build/envsetup.sh && lunch <target> && m -j$(nproc)'
```

Gunakan `docker compose run --rm`, bukan `docker compose up`. Dengan `up`, container langsung keluar karena tidak ada proses yang berjalan.

## Lokasi Output

Source di-mount ke `/src`, sehingga hasil build ada di `${SRC_DIR}/out` di host (default `~/aosp10`).

## Catatan

- **SELinux (Fedora):** compose memakai `security_opt: label=disable` agar tidak perlu relabel seluruh tree source, yang lambat.
- **ccache:** batas ukuran default 50 GB, diatur di Dockerfile (`ccache -M 50G`).
- **Podman:** `podman-compose` bisa membaca file ini, tetapi tambahkan `userns_mode: keep-id` pada service `aosp10`. Docker menolak opsi tersebut, jadi tidak disertakan secara default.
- **Docker data-root di home (opsional):** jika image ingin disimpan di home, atur `data-root` di `/etc/docker/daemon.json`. Di Fedora, ini bisa terkena masalah SELinux.

## Troubleshooting

| Masalah | Solusi |
|---|---|
| Permission denied saat menulis ke source | Cek `USER_ID`/`GROUP_ID` di `.env`, lalu `docker compose build` ulang |
| Container langsung keluar | Pakai `docker compose run --rm aosp10`, bukan `up` |
| Build kehabisan memori | Kurangi `-j`, tambah swap/zram |
| Error toolchain di path luar tree | Path di luar `SRC_DIR` tidak terlihat dari container, tambahkan volume di `docker-compose.yml` |
