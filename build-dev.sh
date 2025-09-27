make O=out clean
make mrproper
echo "-------------------------------------------------------------------------------------------------------------------------------"
echo "Ciallo～(∠・ω≤)⌒★    清理完成~"
cp ./.drivers-backup/FT8719_Pramboot_V0.5_20171221.i ./drivers/input/touchscreen/focaltech_touch/include/pramboot/
cp ./.drivers-backup/fw_ft3518_j9.i ./drivers/input/touchscreen/focaltech_touch/include/firmware/
cp ./.drivers-backup/fw_sample.i ./drivers/input/touchscreen/focaltech_touch/include/firmware/
echo "-------------------------------------------------------------------------------------------------------------------------------"
echo "Ciallo～(∠・ω≤)⌒★    cp完成~，准备就绪~"
echo "Ciallo～(∠・ω≤)⌒★    3~"
echo "Ciallo～(∠・ω≤)⌒★    2~"
echo "Ciallo～(∠・ω≤)⌒★    1~"
bash build-main.sh vangogh