#!/bin/bash  
building() {
  echo "[" > all.pkgs
  
  if [[ -e compatity.txt ]]; then
    compatity=$(cat compatity.txt)
  fi

  for i in debs/*.deb; do
    # Kiểm tra file tồn tại
    [[ ! -f "$i" ]] && continue
    
    debInfo=$(dpkg -f "$i")
    
    pkg=$(echo "$debInfo" | grep "^Package: " | cut -c 10- | tr -d "\n\r")
    section=$(echo "$debInfo" | grep "^Section: " | cut -c 10- | tr -d "\n\r" | sed 's/"/\\"/g')
    name=$(echo "$debInfo" | grep "^Name: " | cut -c 7- | tr -d "\n\r" | sed 's/"/\\"/g')
    vers=$(echo "$debInfo" | grep "^Version: " | cut -c 10- | tr -d "\n\r" | sed 's/"/\\"/g')
    author=$(echo "$debInfo" | grep "^Author: " | cut -c 9- | tr -d "\n\r" | sed 's/"/\\"/g')
    depends=$(echo "$debInfo" | grep "^Depends: " | cut -c 10- | tr -d "\n\r" | sed 's/"/\\"/g')
    description=$(echo "$debInfo" | grep "^Description: " | cut -c 14- | tr -d "\n\r" | sed 's/"/\\"/g')
    arch=$(echo "$debInfo" | grep "^Architecture: " | cut -c 15- | tr -d "\n\r" | sed 's/"/\\"/g')
    
    size=$(du -b "$i" | cut -f1)
    time=$(date +%s -r "$i")
    
    # Sử dụng printf thay vì echo để tránh lỗi
    printf '{"Name":"%s","Version":"%s","Section":"%s","Package":"%s","Author":"%s","Depends":"%s","Descript":"%s","Arch":"%s","Size":"%s","Time":"%s000"},\n' \
      "$name" "$vers" "$section" "$pkg" "$author" "$depends" "$description" "$arch" "$size" "$time" >> all.pkgs
    
    # Xử lý compatity - SỬA LỖI CẮT CHUỖI
    if [[ -n "$compatity" ]]; then
      exists=$(echo "$compatity" | grep "^$pkg " | sed "s/^$pkg //" | tr -d "\n\r")
    else
      exists=""
    fi
    
    if [[ -z "$exists" ]]; then
      echo "$pkg ($name)? "
      read -r tmp
      echo "$pkg $tmp" >> compatity.txt
    fi
  done

  sed -i '$ s/,$//' all.pkgs
  echo "]" >> all.pkgs
}

echo "------------------"
echo "Building Packages...."
apt-ftparchive packages ./debs > ./Packages
bzip2 -c9k ./Packages > ./Packages.bz2

echo "------------------"
echo "Building Release...."

packages_md5=$(md5sum ./Packages | cut -d ' ' -f 1)
packages_size=$(stat -c %s ./Packages)
packages_bz2_md5=$(md5sum ./Packages.bz2 | cut -d ' ' -f 1)
packages_bz2_size=$(stat -c %s ./Packages.bz2)

cat > Release << EOF
Origin: MrPewiOS Repo
Label: iPhone/iPad-Jailbreak
Suite: stable
Version: 1.0
Codename: ios
Architectures: iphoneos-arm iphoneos-arm64 iphoneos-arm64e
Components: main
Description: Apple-Support
MD5Sum:
 $packages_md5 $packages_size Packages
 $packages_bz2_md5 $packages_bz2_size Packages.bz2
EOF

echo "------------------"
echo "Done!"
exit 0