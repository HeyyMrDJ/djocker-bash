# djocker-bash
Simple container runtime using chroot and namespaces

## Install
```
git clone https://github.com/HeyyMrDJ/djocker-bash
cd djocker-bash
sudo cp djocker /usr/local/bin/
sudo djocker install
```

## Create Pen
```
djocker create TEST02 02
```

## Port Forward
```
djocker port_forward 10.0.0.2 8081 8080
```

## Enter Pen
```
djocker exec TEST02 
```