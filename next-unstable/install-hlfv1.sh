ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.17.0
docker tag hyperledger/composer-playground:0.17.0 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv11/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� k#FZ �<KlIv�lv��A�'3�X��R���n�Dz4p�#��I�%��x5��"�R�����׋�6�`� �� 9g����!�CA�S�"�$�5����&EY�-����U��W�ޯ>݊!`+"=Ӱq�Ԥa�2\]�{ڥ�)q(�t��&2B<�KK�O^���'�t�R�O��%?'��-��HB�K:T��Nk���Cl٪���u�:���:Tel�8!O'�<��tGRul��R��Vڨ���u�&�4�t��T������%Bt}9�ϑ�s:v��u@[ܖ\�a�x�`K��Q�I�<X�M��X�R�R刂#d�Ab�N��x�$����*� �O���%�:wNf����g�?��J�v�h��O�<�	��?�'RhA���LR����(��Z�kIv��ג1
/�@�B�"����ŭ�����F��(��Y��kא�W�)����-��[,�+/��[��Ru�MC��i�: � �0 �d5A�oZ���2��,Y���EM+���U��)�/@+�!)�S��B����!%h��""�ڮ.;�"�+9�@k�tY�gb���ru]�;����N�c�7nrO9�Ư,�P�
!�F�'79�����`���p=�CP��a�k���#��8N'��5�S��鮦�T�Q�|R�\[��$q)H]8�z�rD�,d��Q�M�>#R\�h�F�dI6�c@�K��P���L{�O��t�Y��1��3��E�l>0vd�����ɠ�q��X�@u������Vr��)2tmH��.� ���vI+�V4(��{�����DxWx:]��j[��pMÒ���5,;��U�.2L:9��0��T9�5D��Þ�1*{2bᛜ�h�C8#��!xtb�`����%
�k�&p����Z���NQ��h��@Y8<P�ے�)�����m-3��Ț�m	pZ���T��I����)�����ˋ��?��s�q����D����B<���8Y��3���_DayRb�0{XwXvf˖j:��ߌL�dc������5Kj�͵,� �$?�5�^v#��^���*4ʵ�������-��K������� ��%�+G� �]�rao���*oVo���f/� @��\���m��m�Gt��!�ٸF�V�^3�l|2N�HVח&��Y�P9��VSl4���Jis�y2�`�x�S膍a���!L�^�Sl$-����<�G��o-]'��G��#�4��ʏВ�����_����DVs�
���t���V}zM�C�Rē�D&�tZ� �X�M"��1��c�i� ��A�t7�v��ߔ�XTD�mC?��/y���Cl ��@�JR���������L.L�k8��Ǖ!|��{��$�Gy�U+��״�5�h�1Pz�0+���8.�8��l;�t-���6-�Pro��bZeahWIx�ڧ�ل�@8��
�6�r-��tǴs��t�VT6z�����ahv����(!�u��E�h���2�K�D0�.��8k:�þa)6�=b,��li�| w%U�؆�ҽ��c���\��\US"�%w�ClӁ���"��V5��L[c��x<(�w�XW�.�8��@L?HD�Q~���t�T��G���FM0�^Kv�e�z@��={;<�7�<g��������_D�����2���0����%�?��$��en�ow�a���!�al�JO����#8�����,�2ir������)s��ˉ�?Z��,�,)_��f�B:3e�||~�w1���ު�����f)�f���U�ia�Զ�:�G�T4��wÅ�g�"4w2�Uf��Ԇ���x��ߙxZ�����r���#.�U��4���?��3B2)�����|�/��y�_ᭀS�f�����9'��|�1e��o��:j��� lY�u���;ޅ�^O�;ʑ#��m[��7�Sn��نG�%��S��E���ѹ��c�6�U�ܨ"��o;�ǰX���`$�&ºԂl��l�4	��^H=S���(;�~�q5ɲ�hu\��f��wI�--�H�Aqr<�����ɓ���Hk�M�^�_+WW7W�1�	�̤/�!���:xG����^e�X�跰@�m.,�]��p��qf��]ο7<b �&�W���E���!�W��yr-̉�����.M#��_ӽ�ݩ��uq��Qj쭖�V��ѡ^L�|�$L^j�.k�`oړ��Jb���&!P�M�L#��9�vqM�"ྤ�xgt�
`�N��h3s�Q��ߜ� }�|��y����^�D�,B�]��Իpck�!ah�M�gȻlB��o��Ak�[ޱ�k�9��$tD��35�J��5λƎXF&,�Q���Q�,�������@<,Q`� �e�8���ˤ�^031��S��z[�8��u��{�����?0���(��+l6J{��Ae�Vج���jbs}�=ی���4]ݝ�D �g�>a7Қz�J��-zWv�tW٫�l�ɵ|�cn��7����[ZΜ��­���ƽ�Ͽ�)�or��]Dy��om��m/�#D_>IXD5�{Cȑ:=�r�_J"�G�KA��5I�K��8��>�G���C�O�'K/�K����t���K�4\���fv}ӊ8/o�����y��8������d�p��s����G�������|<��{���@�$$S�|��B
,�sh������
�e�Q$B�h�:50�%�-�`_+~��n�F�
�t��B0B�� �E"n����w���AE���4�`��Z}o�dp6�ICԂ%/]{(��d5U��e¾BQI62%R��e<Z�y����enC#d�{\ވ�G���x���5�c[�����W���?����k)��!� �VG��#�m�M4�1�z��Z X�rT�7�e���8�S(�T;�İl���Dn]L4MM�)��	���x��ץ�[�~	 7ɇ���.}�}-@�mT����+��(iH������f﫚F���[�v��������3���P�)1S9�S���M�Qe��\��8�l
��"Tv��5\MA:��E��X�����ɫ�:#@`��K����l�-*(X��������XD���%'��9y%�f��c�3ڴ�E]�
���,T��ɳߧJ?`.��\$��,�)V"���`�>h�� � 
���Z�{�qMC���zC��`�D&t�G�P�; C�1"(f����!6��d�q-��&&�Z�3����� ���rUVMIˡ�+�J���Ɠ�y��o�I��KOd����ق'+�I���=<��	��˝�rװ�]�)�l���`>�Hդ�������aO��|���:�t���=��j8�6�=�4��F!��N��ބwX$FttT,��&Ɓ��Z7l'w���T��AlˡL<�#N��,oV}pz������H �%���Ǻ-�n�E�M
�zZF"�F�����mX��;r?�{�«F͡	ؤf�jT23�J��w|�q������уG���H)ɛ[F��J������	F��0ڢ�Xضq�"'�O���K�~S�a�u�R�pI�����K����S�cF�E�R<��D�'�o�G��Y�o6�� �����;@�����GNqLDi�*�/���=i����,���V�v�:7i�a��� 5�E_�Ôl~耐��F�����4��6�a] ���R%���Y3�8�P�g�Q%�F�/0M�g���G��;�s p27>���=�$kc��h�&�L�ͺ���v,�/�O"�Nr�y�8 ��T��5�A-�@�F '`���tpXv �z�mcT���Y�n8��Ɉ֔��L����Ƴ��S��(5��|��'`NS���Jb"9��h/N�nC�>����z~c2S>w�8q�bB���+Dtm֊�uMvp�g�����y���c�ߧ�8���x*#L���҉��߅������W޹����_����_����]�h��dR�.�e^�Y��j'��l6�ne����p���t2��&���̦�Y��YN	��T*�G�p?y��FC�ɽ�����Y˄.]]��.O��Яs��?W��r�'�'�|q���1�p�{��N���B�r�[!n��wa��	`�� 7�����2 -�A�&w�0^��c��l���g��������h����Lħ�?����_L��WQb�����2��?�׭��-�o����_k�������|�;����B�s_����ܐ{t��w/�����cwz�GU>��L'�
��R2�d��'�d��$�,N�����TR�
)�ZVxAH��嬠$�\E�j�{��������|����\��1�o~����c�� ��8��x�?��lL����Џ?�e`��� ��x���?����sߪl�B��~���C��>�o�$��FHɗ��UT(5���rAl�h-W)���BAĽ��/��N�^����./o�r�{�u����������t�t�7k�zQ��U�v�+�w�;��Z�og��Ԭ !��.򕍺�jKʽ���,=���-?�T��U�\z8�v���Ϫ�����J^f���z+qO�l�4����k�~�z�j��Jޠ0���J.7Pī���z$
���Ae����?��n���~WY�
G�|���w���Ӭ4*�Z��7����^v��i�Jc��*Ҷ�R�o����~���UMY�V��>�(�0~yp����}��[k�u*�~�Ca�\iP���J�\=��������~� �w��sQ���zG,qu�O�������ƽa���ҍݏ٥�)��|�k���S햷��fk�W7��4�o�����j�p��?�k��4 ��R�]Y�����F�&��cy澳֫��d�{ ������W�b�ا�M����|�H4�p���R�S�I��$c�:�Sr���I�{x/����a���1������d����[-6 eC,w
Ck?�m�;�]�ԩ8� ����n����֭��,؊\�=ڸ�v
��4y;��lm;qM_�V��9p�����%�ޮ,��[1��F�Z<n.�?9՚ֈ5Ʌ�55Ī���To�X~mh|�Q�ҁV�W_>*��*���n���S���S�N�pP��ִ�+=(V��m�&7�;Ц��8��
Z��
˃��c��z���h4u���#fW�ۉ6���m�m|���c��7+���|��&׹��6���e�E�?��ંb����n��u���(c��y��9��1���	sC�]/������a_'F6
o�<c]����������QÉՑ�*�7	5�c��c��d�X;a��td�3b����ql���e�����C
���n)�
N3� r���X�2�İ�\۲"����t���v�^��!�e�luV�j�j{=���*�@B��T�eU��P4[dv��F�����g��?֒���<�\u���2^Y`F�p�U�bm�p5Fb�����X���U�>�k��b���d5+���J��D�����O�uh:��}Fڜ�qxX�H���m�\�l�i¤K�Y�H���3�w�7(���5r>U��`^�K�b���:��(զ;���@m��?>�1د�/�*��L�'H��(:����)�����hv�GHU�Ó7�]�4��s��*�@��$��O聒�J����%��y��W/ %�G��a�����Ow���z�DJ^c[����E�7��3�M6iN�Ut<�h�*]�	���W��oœ��t���Gh���:Ɵw	?T�xE��q؂趠n��N�j�bF�q��D��P[�o?u������
M��'|"n�l��+�������"��cNb�u����:F]Al�:��+�	`�����q�M��
���a+������`	�+�*|y�����^�"qo7��t|��~��7>튓C�����W�ڜ�����������ts^�f&�t����u��B���|Q��`��|�¿}��۫C���𿿆����������������������|������ۘ/E�M��ɚ;U�Z]r�91�2>t̯��~��z��;q�Xx!&�.�\�sT�r�G悞��ϙ��.-�ꊣ��U����	��+(�(�������
��*�0DzUc�H�J�I������VFD�M����QSX�{�b0����6tH��ڮ.�8��q&,{�;��~ -��)�P�`�,S���Wa��irhΘ�{B���`&!�jIᮾ���c-[�O�)����"�)RTd��偁�;�W��C��z�=S�~(}����L�uw�fW�c؞N;l�]
w�Ä]���;�A���ݘ,�P�=�4dg�����fV7����I���N�������h���l���֓K�Ԟjʺ^��F诇��E�_|���VX���wre�t�����c|�N��Ż�!`
�۩#a���:��I���ӱ�3���=���;t��GL����_el���&>-�C�r/c�� 
�Ҍ6�5i֛hO������l��j�T���^��2�q�m�ݨ��}9���&5�Y9�F�R_eH��TUE�	�.�0�P��2�0L\��,#��bi���t�s_k�_�n7��[)s��<���ʶ�R��DY�����4i�(ֺ�t�MW�w\�j���`!�:��!�xj-��PݶZơ�����Ū荹j 	�9�]	:=D�2����iļ,�?��&��G��j$�dwHu3��n@��f냡�)�$��t�<��@����z��"�W�z��1�@�:��`b��1��9(й�}<�������-�!9ћ�$js*�+A����D˛��K>*���&����FuD%'���3�ɾ��Py?\%�:F�{
ծ��%Vd��l[.�
g��˛RU#�#�:�
[�R5�0�)����e�q����!��L�Ko��f
��p��^<8L6h�,6ַ=xmM�Xa�m���P����������!<ԙN��ե�P��A�>ӥ_�:�n��Гn|�5حd~�E'��з7Z���*��0��'����h�;�a����M�K�d����8-9)����W�7?��#����t��׼�.|}�����#�+6���X�`p=��>�@O�MztV��9��M�
�-���??���4���e�����"��=Z�������������M�#��k�o[��V/�ɧ�
�������?YR���xb��y�	# �+�o�߻���k�s�c�`����Gi���=��1�
ޔޔ�T���z0{p�{�l��U[��	#�O�Ɏ0��_���~~�c������{�g�����k�d}� oA������� �|��)�.��0�?���׵���B������O^�?��� 3�O�Xf}� ���g��(|�#���@���X��� [� <���g���2B.�߱���!9�f��$C��FZ��@�'�K�������6@�ƻ�md�c?,r���{��@���L�_�30�)����/��߳����������` ������c$��i d������u���r��	���@��/��`	@� ��e�\�?�]����_=� RG.������?�j[������j[Y���\�?��3C���J���%����/��f��� � ���g0�������E.�L��2�cwF��f ��e�<�?�\���SB>��!Qqa�Lˡq�"�G�.�x���ʄ�Reqp��<������ a��s�����:���y��A�:8��͖�9آ�kB����*��C��"[�؀��$����^�`��\ZUT�"�J��lm���P�a�I��e�5T�ɽv-��v9,�}k����R9w ��D�,��'���Zӯ��X�?ú��r��e��I��A�a~!�~�⦲��s�<�P�3;d��	��������y�P�#;d��ׯ��`��^,�����e���X�WPq]i5Q��ea(�jŘvܕ��?�58jUFk���_M��a�������ee:E�Ɣ@Jk��ag3�ʕ�rM�U�)-k^{ [l��"q<X�dsfб��Ku.�����S����`�7#d�덳�?՟r���e���@����?@�e5�4`vȅ�#��G�@���G��_�ƭ�k�~��,Bn��b'V��ON�Uz\�ݾE���}Y�c��d�w۠��6�V��L��a�����zX��ew{�-ReݚŮ��%�� ��� ��Bwڬ�V]*k��,�Z�尶]5	�6�yv�0��:�^�4e����J��mẙ��Vs��4��ǲZ���;�\iA�:�@��o]_�2��5߹��4�t�|&����`��!�&:e�ѨE4����N�|���[v��#���JyW�x���])��R����zK�q�a�Q�ZLK��5�9�����@������>��F����|����H�����_RA*�������g��(|���0��4�*��
��CZ��������t �����_�������+��/%����>/���/[���Q��+X������K������?���`�?X������G�`�������������g�����/���߳��* ����_��//y����
=�ߜ �>�F�?��c��o*��S��!`�*H��o������9 ��Ϛ�Q���_�Ȗ�Aq��������2C��2C������?~��/X����� -$����Z��?�P�� �@��l��=����K��0�AnHf ��e�\�?���B����3�0�GF.��=�(��1<��y>��8��G^��Zu1F0�Y����������?�E�X�B�8��ęvv�4��r@��_N9 �M��Л�
o�j:��%�rJ$5��~k�����tdS��%H�6�2���^�*XgXB�ʶ��qc��Έ��z�|{�$��O�$�<�Ҋ��up�fmR������h0tEr&C�%�	��қ���i[�$��*�m��H@0Kj���0Q�&ɢ�uM�������wF.�r�� �#d��@q�,�������b�_��CJ���␩#�������� ��A�GP�������8d� ��e�\�?���!W��C��\�0��@�GP��|�ȅ�Cp��2B��o���h�r������l���ǐ���0�?��q��<���.[� �m�#`��m�@=�˴K �[�y�����e
��Ï�������K�������o����}_zG�/V_`V��R��>�.r���X��"[�؀��է� ���z����PG���ZȨ���n�Ր�q��Etq�b��jcW�ͻh����be	��W��j�'HR<\��e���@&�� -����[Q��j�w�[1�\�wMx�E�[�wqSY�9C�?�������L�f�<����C.��������˾9���?���<�?���C�������Q�n�2[�_�9bՙ�֣��j�҂��H[��s;b�6��b���Z}=�'%.F�5���N:D�:�]E��`���k��Z�n�m�QH�Ԝ���nOB����(�OE>��E��"@�O���z�>ŏ�g�\���_����/��������� �	���/#<���D��ܭ���i�6M�������bY��^��� ����y5 �c"�y@q�kk"��Ҳ�"P���š��&k�v�ÊۡU� �hh\Q�LE;�Ի+c8�r�n{{ªלE(�U��/��;q�x�S�%:�������<��^�Z�cY�]e�dL���;��D�-��W�9.v�D@�w�=��������ӓ���L��g���I:������C���זJS~9/{�4�2y��73����{a�Wt9l��^�S�b,��zhIx�u��H��O����/��w�ь�k =ѵ���/b/H$��Be�NGK����P����9�!=������i^�Y���b��D�}w���Q1�dg��ٱ7�����.`�t�����Y���_�!�'����E��0ӫ����w��b	
���/����`����ﳞ�L�Ft��<O�Tʓ���7b��b�$IÐ	��x�����<��I0�W^������P��"~e�_[cW�H�6h����e�,�Ɖv��*{�"�'V��ٷ����ܢ�a����:<����������O�������UWP����9��H����̫�_�@�Q�H���6Ń���Ky�&!�""��L����4��l�FM	i@q!1��$xD�`?�:����/�~��k�Y*j����g�2�1ŏw�a���C�9�l��Ә��R����.W��Z�H��Z��[���'���"=�a�WMA��o�C�����_���u�����o�����{�?�w����
~���w�&���b)��(���#�W��?������}ժP�!(����a`�#��$�`���G2����{���_��?����H�Z�o`�~�2������?����:���W�^|E@�A�+��U��u��(���ǡL�A��;��x5��aH��B����,�����nu�ޔ��~���)�^)�^T�̥�i%&ߋ�T������ot�q�%Ӱ�v��c�b6W��}�;��G��⟱Ɉ�ck^ߔ��'OM;�:ks��,��L).�roT���^����}�G��������e��Vv��?tz5�Y��rz�e{|�a��fEb�$؉�����_��YZ�����m���Kw;�q�[S�km��2ً�^�9Zcb�K�mĶ<&����i`�f/[�S�W�V�%���,ue��S�W�����DŤ��7�s��{��+�ۀȋ���ъ�ٙ�[�P2��+W���w�r��������;Y/��fK��:l9�/�z&�w��қ�I�d�;	���4f]��5�-qԚ\��!�uu��<�����wDu͋�MȺ��~�3�M�*�����4���Z���C����l�j ����Z�?þ�����z��� 	�y����$�Z�a�'~��՛��~��`z��8�MI=�cn�+�����+����/����_�*���_��$~�Zbp��tҚb���KmY���\'MW�{�N�n�͟^ß_�Fs)��2>����s?�2RS��i��]M�>1��L��c�}/�(��8I6�.N���#g�gc4g�lk���#i��b4䖎�NC4�A<����9S�xk���֧������u��)�*�Ԯu��p��Z��g��sQ4o���饽0eCԥ����K�s���Xm7�A�A����6k����Ap0������T�g��x�n�ta�,&+�6t'	��	���op-�I�W��73=0����9�۹�	�4�0��CS���,�w�-��ޮ�P�����t�!�{ 	�J ����Z�?� ��?�P3��ω� 2������?�C�����u;�o|?�W�c�pi~!X���#�ϯ���J���4�'st��݊ �I �4F�|� {���5 ���E�>���i��: �`<M/}�������Dv>aQ��\/���Ƕ�#�\�aL�9-��F:K�����r�� �M�)c�?����S����6dQ�� <�:^�=�X�Z/痒��XgKjjo_M�^��#-�젴6!V4�1e���V�^OF�0;3Ծ��B��q�����-�DQ{�p�z���E},��V�.�T^yv��.ɃZ���+��_p���J ����Z�?��ʨ��C b������:�������_m��������$�(�C��H��>�%�����k�u��|0��?j��q�C<��0�#��p>�$�萏���`X>����( x.B�!�i��-q���`��D���o8��ݮd䳦0[�,���!> Ɖ������J��c�k��m���;ʅ�Y����v s�ː^�˼&F��v�3�^&�7�Hu��������#2��f�;��-�œU"��ܔa��[����VG����}�����Q����Q���?�6��w��Q��W����#�dN�}�-ۍ�����n��ڼ_���m�ڟō���?7Y���Һ4�^�%w��ϖ�����8f6��%'��ַMor��^���I������(r�LJ�2�Ck����
c��{+�x�S����:<����h�;����P��_��_���_�����*��@X���p�a����g�_�i���=��:���G�]�v1?�Rf_~���]������B���K�Jl���8{ˌj��v��5��Bز�@�l���[�v4ӵ"���q$�n6bq��GF�dƜ����^ئTaY�Y7c7�vzn`������n�}{�o3��n�|�����T�����Nʔ�t�Ӊs��~�,�#QkfY?���Pj�<q��:�tYe:�cָGz�E{F�Y MŖu�;��Vh��3I��qH��X���[��'?BC�.|C�I�3�)b-t�\'�l��7bA$�l���Fr�R�f��0������+P���� ��_E x�Ê�������P�AC�j���+���?D ���ZS@�A�����A�+���pך�J�߻�����H����������j����O8�G��V����_;�����$	��^�a�K����P�OC�?����������C�����x�)���v�W��_��V�ԉ:��G�_h������_`�˿���#���������( �_[P�����kH�u�0���G�����J��[�O��$@�?��C�?��W�1��`�+"����,�a��<��AL�	���B��<�'TƷq�E�1/$4�$��ﳨ�������O$���~/<,.��c&���3��P�O-����vH_Xˤs�I��8�p�ɔ�y0��s3_몏�l��^QRo3[��q'���[��C=z)�J�:��<R�v�@�mw�éU�?��:<��G���(@��OpPOP�����i��(����ă��p��d�m����{���A��A���A�_����*Y���Bp��i��x��1q���0��(��H�x"JX�S*��
9�OB<N�"8������!�C�����ic<[�g�|�5�k�t��LO�Y�У��"韆G�y�����fs˦�+.U�ɑY{TBv�K��s���lNL��!�Tp����l���|���t��C
��8���馹lA���������@���K���������S��GA�����i� �����W�x,T�?���� ��_�P���r�j���\����$�A�a3Du����W��̫��?"��P�T�����0�	0��?����P��0��? ��_1�`7DE�����_-��a_�?�DB����E��<����``�#~���������O�D��r�S�4{9�^�����]�j������Y���ٔ����~���}��pe�'=\&�ԑ�f����Y���6��]����F(W��(�.�YI��ů�ڈM��Dڅ<�k��,S)��=�W���X>�{�B6E�4��~.�v���_l<����j��/���T4��]H̠�=�;�\'�<YO�s��$������*>gb�=Qly8MZ�����ɾ0l�%�*b]��>#�Cs��&�`�ÍZ�/� ��@G���W�v|9�������<����G$�L�aJb�����Y��(��O0�	�?��'���U���������k������Q3�o��/�d�����u����V������Co=��)��|��re��_:�2�(]�wO?5���<)ѹ��̕�4T���;?#�Ԟ���c��^?6�T,Z���vy���Iu�����UT��_��?�NñT�f��Ik����UHk�uW/,�id�nTZs�4]�:9��6z~ͥ���h*{�e����3MQ�#{��#>�RH>�w�E\%��'�&��i��ü{��lb��̞mM���v$m�]������I`�F;��cr>�o�o8�0����rV�Ҙ���5EZ�n�u?��[-k��UwLILyE���)O^_/�)�.�v~p�$]���]��j�Y�Hz�.�YsFv���)���뭓E<Mœu[��f1Yɶ�;Ih>��HhN�~�k�L2X��r(帙�ـ1�|eu�q�ΕM��)p�6�Z?�gg��cly���7j��?a�#��-�s��w	������_��"����Z����G8K�τ4��� �	��!rQ�G�R�E$F8�C	T�'8�x7u�������#�W��/.]ߘ�fR�o���y�w�Y�B�:�ڼm��Y�������c����ȑ�y�+��o�l�f���6�p�����n�I`����_��n�9N��E�>�[-�J��R��boOm�lk0�V�݋�����<rS��Q����º�t�|?Vs042�m�+}�_�*���f�9e��%���#�5Z75�o��o��������t��G�n�>ez����{��,��6�Ǔ���E�qp���y�9�����t�g�n�}��Tߌ���|�q/Z�\q��;�>���quqq�춙m���W=����~3��i}j�����h�kb�MښR.�\d���d�og�c�r���f�OJ�=�M��q8�Ml���}��<�&:݋ݭ��iz�f���D�9��
�+��G��H�������ӥ�����������������{������Y���-�����c�u���W�������f?������O�ӛJ��Uo>/��W�����ע��?4Zv���������	ڳK� ���}Е��RK5�� ��(���l����xsꘙ�����N^_X�H��a�t�nR;=4���J��UI���[N�'��U�M~���v+V�f���{�j��ë��2��/�/��>�e0�?�o� �??,M�J�X�~���g�x����F���~�Տ�J��^�c�c���H���W��ȴv={~b���"�����қ�Q�/>�&ˇ:]��>��7��Y�}�V�p�<���abOu�}UJo>>9.i��^�vjD�\�˗ّ}�8-j�+��`m�љ�3���ͳ��G���ǽI��TO%>N�;�N���;�������um����|6����l~��?JzA��hji��Cj�3x�FqR�u��<���5yyA��ʧة�0�f���G�i�*��*KǓP
�~^hц�2�[v��H��4CC{��=b�2��kF�yb�*�2J|
B~.p�'x �1R�CV�@H�R�(�����v�1�1��b�1���M�L7'�gZ5��F`ظ�a} l8*���96m��đ�������\�������C�o?������8w��xh�}0��`?�J��f�)�A�0�vu��t�k�怈Yh �k� Sӵ$<1O��8!gP����m2�@�O(6eb�0 u�[!���ûM #jjYt�b&��X�v�Y�۶5D	�:��T��R�^�I!�Z싫YL}M:.���;�E���``�U>�� �2��4o�jp�A����D5Gv�eFAlKS�`8a�r�W�"���;o��ha����L�o��^�oo��&8��6z'��@�]�B�@�1�]�`�2��FK]	DH���X�!���>�?k�����L�}J����Zt%8�P6��һ��P�\�o*֥60���Jd�!�e��ԥ֊���\<	|8���9��D�E)�@R(C�bR�8
$�W�b��
$���Gu}*rƣ���D7�k��]3���Ԩ��D�S6]É�<��l�0�Mgr�X�� `�gB�Wz��D���R3TvC^����'�鋾����jr,Wq|�W����D�n�d��%J*C$�a:d�:.����6H�
����tMg �I�nsH�:_��������q�@��*��D��q�S�5�>�tB:��a+��|�F�Ȯ�1�nM�ps{�5��[(!�����繇�%I�N�Cqn%TQ�M.a6���%��G�y �xw�h�}�_5�kf��;֌O�^X���fS��O���l*��\:�=��(	GX�@^�_F"���sZ�Y��6�}��t�,��}�	�2
-�[�c��x26��Xcd�X�Lۙ�uX,�j��r��qV=H0GI,+ysI�v����§z@,A:�k�L�	xz�<�]��67���$����-�I�*1��i`�����$�+���yͦ��ڧ��.�v���^2�R5�fY%I�)��\v��{�=��]7Xi&�V��Y6�R4G٥}Mb]�Co��ф�ԗ�cSw�,@���w}�(l�9�̺�Ɗ����"[��_Rp�����F�RmU��V���qtZ�P==PY���.Vkw��b�Ҫ���8���4�߮�Ϫ��F� 9e]������vn|m�3�,;��A��ѩr���ݬU���-]��Q�ߒ��́LL��KU�
$a��D�Qg��-%�K��r�Z���%�9�QO��'�1�`�Ev��*��_CPd;��� ���SZ_�y��]��X�~|_n����G����2�����Z�ܨ��TK�G��.��J�Q�w\C�)$	�Bcj%,א�G�2*�٬�k���pYO�V��$��[�Q>��Ǎv�ܨ֎.����F��zw���eФ7��~*(@�B�+�7���E�A�}���B�ru۝b�*�V��b�خ��*�;ʗ���JI�I�yR���-���e������Ċ91e ��@6X������
���1'��`Nf���\U3ُk��c�ݹ���v���r��?q�*1C�/�(�ɹj.�o�GPMy�|>���VD�U�h��1gܹDQUJ��Sh�q��	�娎�+%���K���b�$�����캚�Ɲ��Nl�����Tvn�7��l�%	V AK��E���(�%{�v�"�{`�G�|��i~�D<��@jM�Ҕ%�H��H�$f���uJhw�.[n��	�<���tT�/����M�"2�a��\������ ?���n�Ӻ��L>5�����n�%m���?������v�g���]�ٮ�<����_:�Q��|h�ܳ]��.��;m��9�Z�91�׸=ؼ�u��������fw���c�Kt5#ѥ� ��Wo�H�Az�e;�Y�i�%#K3Bu���v<�g�b�T��<$�4|r-Aa>���&ņ�B�G���N�kYx�f(mZ�x����+����/�ft��aǗ��y�\�3��m����_%��
O�=p�%�]��L�9ksk�AK�ѻ�2"w��H�3��� D��F<,64���98�9,������IĽF���ْГx�[�[C��
}$(�'�/��g��tj;�Gj6L����k����v��w�>�u򿻛���4�����?|zz�E N��5����>%``��\S��<C�c��_����F�	�2X�*�5�O����T.��4��dv3[�������K���ϫ��[��L�z�K�{(�x��������Wt����a����?�dZ�r����?�����R�@�Tǃ�6��1��/\Ϙ�!���}�9�� o����B��4^:D|�x`:C��T,v�*���$UA�"��H�Z6�,Z}][�v2�u�?���;$I������BA�� x�����k|��zڬ�������,���7�^������sD�F�*/�����p�`�Q;k6Z���M�OB2�%�;b�&;��D�t4��P�$�У�Oqd�sZ���=�|�<����S�Ŕ!XI���G`�vލ r��1N�S�ؕ�ҬN��(ׄ��z�#��X��oB'�$v'/��W;��S��D�˭X����o`�/$�����^�����>�}��q�[���n3�	���̠	>��B��ʹ�.f������y��/�y0d>�f���:fa@�*Y��3�D��PR�\�,A�2��~��T��Ra�6��.g���M#�׋"D$�'��[�ys��e�8ޚ�ц�t��I&�7�9��{�����|zE�;����򢎏j����m[�`~�f����	��%��x��p�1 |�v7)�b}��B��ŊQ�����m$�t�QPl��a�m�/�[f�/�Dd�.���
c�Ik����:��ݨ��{��^r�X���i��8g�ft�K���;���ZO�bE����hl�%{ts�W����,�9\�?ڷFJ!��I�[��]���`�1�6��. 竊gVᶒ�A�_B�U�ʅ�@��yLZ�Z���x���H���y��}k�+~�;��`�T��n��s�^R��e�{��}�S��=e?�ΰLj7��Ҥ��&�����n*O�>�fw��u�<
ֶ����gF�gL�1�FO�ت4�;���A���q�>]��2�ͮ��K�9�7hШ&+��VO�$�� ����s�_܁yV��E�,��'vf�ރZ�����`��]J��
��2�S���x��E��Y�#�aّ�cB�TEtgFP�x�#�j��Ws�t3d�L}+\�f�����M^J�)$��Fp�$�6�r��� )���ݦ�t���-�¥�lh��o*�;�)�No�#}����up4�j:�L�aJ�����Swr�V����~�m��'����������#m:��������җ�����>�]���c�㟱��~l­��[�?�����P !�l	��Br�6
����$��M&�xۑ#�����[�ٶ��~�޴;�V�S;��u�N-lI"�CL�;ߖ����:c��_;q�F���#�!���8c*N���[i.=���5�H�-�!�78�<�σȾ3�;Y�P<Љx�����K����t#�\!���|���G��M�?J�nR�{����d�WxJ�S��3�����GI?��IQs>Ɐ����Y�/]�����\��&�N��?����'��u�ם6)�0c|�
��Q6ic�8-V�{�7�������*�������=��d�Q�o����J�28��t>�ʦs��e���V�?Fz������ON�}B�ʣ|�����1>��"�z�~l�����+BP�B��9(j��`r�yA�;E��?wLS�fv�d���kX~_~v�E�B�z��^ �_*��*��
�%��^m(�-CYp84w8Wſ��X��E�U�y�Ra	�%��Ŋ#��[[B����& �PL�{m�0>�w���E@Q�g�����&n%ˈ�S�C�����4?svd.*�!X}�̜ΠT�����Q��;F\~ʈ�x�Ed
Bj�����`x;�+�Jx�~��꺎�x�W��Y�ZЂ��+X#F~]"/�� ��ap $�a�x����>��c�r��σz��n�x��'�N(~?"�V���BO�CE*B����*>�� �7w5ˋm�U��a��d���j�o$�;>0�@�ygV�z�r\���P\Ks�~�bom�W�7�]Q���eĳ�Y�ڊ���z�É��R\(]C�N8lLz��9�y!C��'�i��O�Q�c�^lj~��c?PA��A�? a���#H�𠍸��R������265���Ck2���g2��W�	_��2���Q8؍�&"��y;{��x�_s}��Z����π��kd�y�C��?M������j�Ł�	�5��I��<����z��FXJ�"��~9Q�l�OZ�q��H���z�� �m%��[�xpT�ڦnF��D�����8!�-`�vQU-f��Kʫ�I=tK�ޗ�Q�t�Q��ҁlē/?wY�����JI�r8�$m������,ñLݞ�>��%4�Kg�Y����(􆜉����Cz��� �YC߇��ʍ�/{��8���{g{k�L�4�m�.MiwA�����i|K�$v��΍F+'q'�ss�$�A�Bڅ�Zм��m�!���� ��
���h� �έR�����N´������}�}|���������VA�������G�l��e�����jU~�ݪ_�_�꺋x��s�>05˻��q�;��1�-��Z^6LE��f�s��Olq�{����޿�����K�x�sA�V7�赿lq��{Q�I�q�9���i��c}��G���I�������A�����]ޭ��<�.�_�p6&�r��p�BRF����?��ϝ&v�9����:E�J΃� �S0�3�fr��j��b��_���Ҭ/J��e����:��f߇~����`�_a�'5�N�����ێ(�6�v��������Y��j�7�������k�����]��e�q��� �!H$����x�m+ �s|�����;�����G���K�����5C�h������V�RѨR(����!:F`T��`5�p�B�dG�Q���6��mp��}��1! �}[z��� ��@o@������_܂�{��E�:�u|��#pgn����W� �����[^����R�3n��z��U��`�NN��'�,Vu�^��Z�w=�\���va���c���'�H0��pt� ����R������7E���?�����>�ٿ�[_}�/��!�|S�k������s�x�����X���?ĈH4R�5X�"u� u�#Y�GJ'p�z܁c5
�u<ZGPohQ
�G�_<������՟|��j��?�~��}�'7�)��G�݃~߆�߆�|���0��з�8o�A��:��חD�;���}�1����>��}��/-�M���3ϡsAl�Ų��Y����d5ӌFՐc%���[��pt�1�~���de��[��O��7z3m4��]����(��/���5��rK+e���+�z̅'ҌF�Vy"�d\lU4�l�(��e@L�vF'ɵ�
m1'������q��W�P�j�j��������(�-`F�N6��WC���k�1w^!�O��k�t�����[���2J9b�u�Ƽ���*���+��.���,-���s�\�d��A[F��p�v{f������f8��q�~�7L!3Gj
*׳���бLR.��v4g��4�#}w��s*�Uě��c�9������c"]�&��A��;��,*�.��LxF��)�e�وk��'���@~��}���$�6�1��Rw�.��F���N'_�r�%s�`��A+l�-�)k�!:`BE-|2�*1=��k\y�J�V�����ڸ�W�����W%���iRBOWx 7�ha�_����/�Mq6�����(c�дf��n�4�|ے�$���v�T���URy���&	��2p���>1�ʻn�{e�����{�.M(ESFF��I^����Jf9Ul��5A1�$���n��Se-E�bZ=o��HV�J��R��b=�#*?�n��(LZ��8�g����m�ஐ#��*ڈd��\���:�^'��-��l�M4�'0M�M�n�"����bÔL �7�U��cQmF�E*ܴ+!�p=oU�@��z��<�"�)9�wc]���+R�(J1��`s�b9�Kj��(�;�
x1��Q��?N$��҉��|�Z�~\R�Ŵf!I�ʱ����Aw"v����X��'3�˞������E�e��DO�Mx _��
\M\O����)5�,1��\�L�"M�*�qL�RT�Zkj�cB�*&�v�ZG��XJ�f�fQ ���a��kթli��ݞ���L\.~�J�<��!+]�bi
�5@��4��2����n�\�F�4��X�c�� `��(BG:n�nfȨ���E�2�x�IF��
t)M�cΒmT��T�$Ԋ�Բ�78��n4��8Jt�f��`��o@?oB����_򭷥��>>��~��n��k�C��r��|��g�f��;�~zٳ-V}?|3��^z��+=���/����������;���ћ~o�E�wބ��5�����k��T�p��}��﯏��v)��g�յc�/8�qF�L�)N%�̕�z�vF�k�Ӗ�1�ίd>����57� �wq�ϙ\Gk=�b.p�y�����d�7���:��$2ꊁ3>�nj(�WQ�
�0Fm),�Xp��J,M���'df���`�d��e�XK�Ŋ�T�� R��r"dv�l�L5k�v�zm؋�Τ���h�8+ubI�z�B����Й�D�2~.���,o8]�(���4Gg7�F�}2M�Ev�.�9C6�Ѫ��c2t�0i���I:Z���h2�ʱ|�Y��r{F��	AiH	�cxڤ͒>mgK�*�4�N����^"�v)�i�W���V��C�f�<��n2���,=T���Jb� Z��`*���E���o^:iX_Q��e���ڑ�Q:�Gә�1j�fg���Ud���O�V�c3��R����\�G��UV�>"r���מJV�+eܺ�-���j������ts�E������X�Z�Fr�j"l���dd֪;C��:cC���,Z���T�p�m�u)�������,��0��ҺSqs�
�x�U_��5�V;\�h"_�K����:-��BQ��2+Ҵ�ZL��ʮХ�bg"�]C�b�KLƆ���b���l:�f �Q�B�`�I��{��B��Q�V�f�x��'Ŷ��{|2O����4���+"���r�7aN���D��f���t�fO]��SM���UX�F�3��'҉���9!)� �Qw�]2ɑ�PL���"��ĭr�$]7N/�$��-p�%1�΅	���J��c=�Ba�y��J��|u~%P���{�@�'투j)�V>˃,�����q����!�(��qE���BJ�,�ʗ�0�8iD",U���5���&�Κ_�\W���D9G��j���#!F��3Wӑ��ve#9'd<���I�����	��
�6�f>� ����d���B��(t�DM���0�u��y&c�a�q�2<�:UWd��#��
�0k�T*�"��pV��h2���ȱ^�+��<�pC/}zySu[����ƫ�9V��|�Z�Ep�����30��!t��x�Kி�������@݃��M4�*G���-'���K�ޣG���=z���5�����Ep=��^�g!+h�Y_��n���7�R���9}�Khæi�e���_�K�\���+���4G[��w�����;�_�����rp֛� :o=n�cm��<����_������>|�����������B���6p��_G��J���@���/���
>Z�D=Z���;����'�]ˏJ�S{�Hk4L�\�3=��w����u��pN���ёϓH�oƜ�W妁��&���>ڌ��]�+�}S�w���z��7uC=�o�zh���=�z�����+�}S_�C��Ψ��M�Q���Q�ǚ���?����{��]�H��Żx������S?a��N�0�0��3��	����^������OqM�S�~�7��������d�/J'���G H��mzRVe�� ŗ�w�U�Ui�;�c��)��8)��ѓFO�v"wA7���6��F�JiT��f�Kw=$�J�g��tl:�"��N`*ѳE�8������+]gz�����M��y6�Kڸd�{��<e��8�[A�U/تl�;��??f?�?���G��6�3�o`�w}������g�����M�o��e� �	O�/RA�8�j�r(�n:ͤ�f�2�U�.�d��GJ�/Z�؊qzm�K�6:jz�$Kӹ��ʪ��j{�X24+`�ꆪ�q`��:�s��Y:�h�4�f�V�ݑ�AuT��aNM�\B���Έͮ�n��gnl�O}p���Q�Jm\�����b����p�p���n8���:���&#h0������xb~W�c�A�����?{������oGx���2a�w�q���?9�c����'������l��)sN�v�����=���]aW��S����?����?
���p����.������ա]"����w���s��	���}����k�]�𽞾'�?���_���@��?���
��}Aؾ lߓ�����}���>g�G��m����� �
�n��Ϸ�������#X��
���������a�,��?�� y����@��	�c������?���oإ��X�`����Ϸ�����g�$��m`O��k�`����<����[A�m)ȶd[�N��]�ܧ�����gإ�������S��������ΰ'�l ������;C���������^�0�;�.���>:݁X��C`�?���>�9��'��_[�^��@D��Q��k~���W�c��VoD����Q�aD�ѨR�w�t�����������c�?B���������<q���utb&G`�:U�2�$B�3�JR��L�W0�1��e�E�	E�ɲBCL_��C�d0���ד<9-��-�*����xŎ��^�GQ�1R�j�\/i>>���n��>�� ���+��X��w��?��v�}�� ���K�_4��g��)<������i��f�h|�e�b����%S!��郢+�Uΰ�ȉ�FF9���R|���K�ݩ��܏u:HI��Hx<��V$�G������TC�'5&���N�]﷒E[������١6�����*�C�G����c���e����W�{��e.�"*(*N7�)pE���f�NG�7�~;Eu��Ub� �UkU��wA(r�з`�/�_"�_P�U��꿠��`��_A�?��Oo��������Z?�_ˉ�]5I��D���4��:�W�q���OԵ�66��_h�t�6~��F��mSiK��Mg�
4-���촟ֺ�������$Yc���0�����ф:�6�r�dc�j7h�a��M�h��i�kFc����V�Gu�����*���Ƀ��z��m�wZlT57��򑦹^�z�u�A����"�v��7�F]Wg�/j����z����櫪3Ce��ٙmwk�q͠j"�EBK�M��j��Լy�&Ǒ�ʪʧR��;��$wֵe�/���o���F�����k���h�������Ip��$�F�����X����<��������o�?
���8�:<�\�������<���0��?���B��x���a���<���_[����,s��򿘀��a�a ����/��X �_��B����A�}��s������H����3�Ü�@�����p���X �`���� A�1��*
��?=�?��q����y�����ǃ�������?`���^��ÚP<����������+ ��@���,�|q ����p�W
��)������?3���@�CYH!������������� ����(�������	��tCmHq �����/@�_Q ���<�>D���������q�-�������?����Q�fjo�6�~݉{���T���q���f�ܞ�9��2X�O�e*�TB=}�D>�۪r8������iC�t�EiS��;I�k[h䰫�/q�0-SVv�Ȍ~�Gigjs�i���'�m���n���^B]�@�Mu-���N�杋C4���b$��X�A��ih��:5�J��-M��rX;Z�݊�	��r̮W�e!3����<�S6�E��GC�ur��2v�� B�1w�?@����9d� ������ߙ�	�/, ���9$~����g��c�������?���W���搅����D�?���@�CsH� ����a������?~]�������"<��f��/�����#��9�N�G���^� qR�(@���	G�l$о����F,K�J(0AD#��"!}IYb'����G�?3H�N���P��/��c�/�������556T[�M��5�6�\>7+���s���t��{����ԝ�k�o�Ɖt��&}�1b��N7�;�z����L)M;����w*�6C��8ĥ �!c��Nr.���b��̅`��$�r�I]<�3�4?{�z6;��y2����Ј��*n��S������߻yQE_p�@���?�C����C߂A����8�����0�������})�$H����O��d�_���6�ZyBSzy���\s�]��U��-�e�������I�z�-�$��7��5�,Wr��T���F_�\_�kl�<99��k�z��L?���)���49��e�k���� c����"H<��8P���o��3^ٿD俠��0@��A�����"�@�� p��
�[�op�q��kN�D���̖�� ���&���뿧�R��^@��e@i�{�4�l��[�̤�T���鞖{��i5�+s�O
�(s�|,K�I��]o��Z���Eg5A���#�Kζ�-�mq�Y�QW��!5��O:O{x�V#i������'����U�ܮ��H�+�
{��˱�Hd�\g�_��●t+�pY:TE����S��o�h��_��z�7�b<�/���Y��_��Ћԫ��d�o,ЦS��Nb�o����\���zZ����MnŭC�I�!�-�@ɚS��F��֧~�6�݉7�;7R�N0~4���?�?��F��_ A�3�M��H��/`����^��s��f�'����_0����/��������,34�,{=���G�����A2���W��.�Ȍ�"�.�0��Aa��������.�0��p�O���5q��LhWT;�{�Q1F�Q:�tG�y+0T�(V���)���e�U�P�+[ ��� a�g��P����=ݡȋX������/Z��q��g���_�f��q �K����!_���?9R".`��a^���Y��(�xN�'�b t�+
這��(�����X��ǂ?��t1���8�[홿�i�Ov���ޢ�>�}�-Xф�������ƕ_���߉+_����~D��4�_����H�����_�?@��A��׭�����������x����H0��À?~�7������w�?�^�?���	��n��b�������-�u��������?���,M���A�,�������C@� ��/��o����/L(���`��_������?��*���})�$������f���� }{�u��}4p��?�d^����/x+���+5\=�\��앲e]��B:�rM�̙kg�Ms���2�����FϾ��kƩ�����h0>+!������Y���xluo�5s4t����Z���S������
�CT��m�CT�k�����_ρQv����wr`��f0�9�E^͟r`G�����M��")���e���W�"����.ˈ#M���d�����4��r��c!�{�Q�6�s�L-OO��2��j��:��§��j�9t�m~͎'^�(L��U:���W����k*�\٪��_����LJ�^?Q��b��'{�zmyV��PoX��([n�Ԉklf�{�mWԸ.��/\k�95G�E4M���ԡ޹�Ȏjŕ�n^^z�L!#�3��K�\�5=qW���N}tn4�q�2���Dtt����kY=$��k�Ůa%aϠ�Ȗ�i���aD�{����,^�@A ������������������ ����o�_��_X��7��?x1��ٷ�}�t��5�J���X�7�_��O��=u�\�e��i|��Q���ǚ�����=�u�Tsu��ym8v/ȝ���=�n�,vp}l����5�k�u/�w�2�罌[��я�y>�����N�6����^�-U3�r㨹��8v{v�<H�p6j�B&�Sj��յں���eǋF��6�hҝ�[K�$�e�+Y�=iw�1o��8o�{=�i��I=�k=�r���Z������\U�������]ؕ�ji���%��j�i.��j���a`�VkGW��=c�B�Gho���/롨��U��*�[�ӆ+R#���Q����<]�K�n	aw=��r�Lʱw���Y9��dS�	2��V�}���ZѳS�W����:�������;�� ��过� �P��m�G�w���7����}b` H��{����a�[���_��K����ð�tm~fD���Ne}�=�g9��a�����D��� �M�zhS�v�z=��3 ���E걧����ͻs �s`8��mq��;�T�sG�m�ƌ�e3i<�y���<T��2����?aS���ٖ�gK��ǝ|9Q���n�|�"���P�A��� ��F�JU�iD)�����.�Z��s���sn�no�}�4�ځWZ�7��2+^����j��WףA��N��eFXT,uؔԃ�tj64�V�?����mjBG:�QTYdqe|��"����@��C�/��/�����#������ �A������ ��p������W B�1w��? @�-�S�mv!�� ��k�?��{�^x���H����A�%я�@�9Z�d%�ޗ�g��cQ� :�x:@�,!�g$���S������o��x�'�Ѵ�7�Zc3++��/R�ڧ��0t��ryXV�08w��?�������Nb{�sU�ҹϯ*�M�c��/���NBu
^�ƚ��2���f�k�!���{�SS���pj�tcW`�ۯ��������l	�������_q ����Ga ��﷋,�b|A������ß�퀳�c)k��ji�H��Ԍ�Jmޞ�;��;�L�����X�'��Yw�]:�2�*���njMf˽�F�)M9�Yqxd�Uk[�F{��u��t�Mu���z�űI9�i�a���zޞ���WA�����oA `�з`���� �_P�U��꿠��`��_��?�� ����~o�����-��z��o~�Z}��*��N\w�n:?�Z�?����Z�=j���ӵ�66��_�ׁԯ��璦�[$��\�e+���(�c����D����UK'A��80f3�t'���7��\=�3eq��f�XL�3�i�����&�n�� ~������r���^U�m��^�i�Q�.�:Wm��b���Z9�ۡc�����9��C���-Y��a��R���m�@�چ[�j�����nOO,��>7�'V�ʇ>�:6�㨻�+%��7ԙfu��Y+M���I�Xf�����8��R��r�r�Ni���� A�1��������ÈW�����u�G��p���"�_���p��x����
������e8����]I.���W�b����0����ś�'��c�#^H�����H��e �_��?�x!
D��;���X ���C�����A�}���/�����$�?��”�a�Q ��ߛ��C�,��/0�����_����w��y�8��������w���!��@�����P��X���.�o��z�������C�����?����b��(���>�˴4A���F
BHy%�hY���޵w'�d���u�}�tONEsof]@T�����Q�C4��|��M41�t�D�i�Y'-E������E����R�LS���A��)9#���~F������>�)��>����ú�O�y7=����H
��q�2_�q����gjU�n�����V^���bc�n�3��mI�!�ߕ���EX3��ύY���IJ7����!�.c�Cq�i��j�K�*}G�1�Bǩ�����t
�j��O���!���?��/�(b�&���w:��R{��������ӤC����4)������������g�����w:�������$���j)�L�Ԕ�V�&�96�Ra&KfG�J�YZa�,TH"�@V�%���S�����������������6�I�tG��:��d�:�R����tc��Ʋ�7�n�B���ˌZ���ؑX,�V��T�3�D��j��ٮ1IFr+����`�N��ӾL��r�fI��d.nd��󤙏��o�S���������g����*b�&�O����!��"�����A����|����cS��1�������������!�L1���t�O�Y���?�����G��c�?:����b�?�������?z�E��������������������{����p:��5���Ǣ���������H6v�?>�� tR��?S�@:���PR���^��C������Β�,��Ǎ2T��4�F�kw����������s��3�{���{O���7��=
���G-���w�׼kͤ6A��B�CV��4��[>���Kz��s��uW�gFL}�;ʜT�E���ժ���Į�*���}B�r\P�\�	/4��v�xb�ǿՍo#���4�ʌA��)�L粝��z��,���5O���k4_K%�H�9��w�t&�W�$��,1a��K1s5)'���ݫ�f�A�*������R�s�/~�� t������������m��������?�N��S�M����;��bb��������������w$�o�����_�b��׶�N�c��htZ��������S������ѫ����U���-��׭^�|�%��ʾa[��ͧX�ދ��M#�~\z��R��Z��w�im����}�/.��S;��g�EB��k�����n�vG,�V�{�ތ�����B��R���<ՎH��De�7cP��jGj��v$�ޑ�>N��i�&��Ox�2~6�Alb[���0E����'����(?$�w�"GJ_���%�L��v�ڳ+�vc��I����D�չ�KVe��f�;�e�\���a���΃|��f%��5Z�!#��zP�t:|��1E���h��mI�s��UoUyn��	�U7����9�
eN�g�P�Y^�s�ӪL���n>kCU��u�
��A]�K�,�U�~h:�#u�*v�)0n��!Q�S:�d��\��K���9��Ұm��A/���.��t9c�j�+�.��\���c�6qӫ�2i�&�.�Z������N��K�y�3���A��)\������?����m����Od!<�+��B����HI��(��T2���ٴ�d�d:�S 	%����UU:C�V�hE%i5����������t
�������?�����}eX�,�n$�Z�pm7�p�s���˝Ӌ�4)To�t�(���of�Z�Z0��B�~/=̉��J��)a^$��Й�,ͅj��E��y��E#��VdcmM�'��^�|���d����V:��?>��xt���3�Eߣ�)����w<:	����8� �G�&�x�����?���G���������������&�ak���LwZqD՚�5݆��o�?�Bg�bO�I��k+7s��׮�2}���m���2�T'[�K�v��k��̀/���N�?2��6�M�#�L��ӱ��V:�����G���U9�:��}��@���W���x���������_q�'�����m�c�I�,����ӱ�wz���#�O�<�����(p2�g7le�O���<{�_����{Nۼ�_�Z.�����@��b �m����LU��3�	��R%�&�W� p���fZ�2�<�x6]��-jJN�Έh��|�:�*k�n�[E�^���Z�Wa�7�����ڵ��a��zk:�\ͳf}��>l�����	�����������#��u��#��&o�0P�d�����=>�dS��s���K�l��N��n��ݪ�G'6��*.,��H�������2<�i�rU�)Hb�L�^Hf5��^���r�7��(/U,�Ό��z�ܝ�+��O`.	�v���gz3�Zb��]���%_K%��i�|7�N���?����<3_-��ϰ���T�!��A��`�W���= �Ut���3M��i.h�P.���ڍ��E�P���I��g��\n.�cxA%H�e�x?B������p���Ña�� ����ɖ�����g�ek�}�*m�� �}�c~�>����3x�U y{&�%ز����.s<kϡ�bBЈH(д0���Ƅh�BB��A�	�r��S�]�
;g-;�/ț��Y����!"���Gɯ��P��?J�S������w-T�V���Pĳ�dń("=���jxHE�Eh����V���E��r� ��� a��| �l�:u����#m�8�����F�dǑW�@����9to��i+\�k�*��^`4U��Z�>=�8 ����o8P�
:�P��E�(��w��H1p�p�[|�g��Ɨz��5����Ǽu�<���l�� ������j�}�
w��������/wz�t���M�}K��H��};�.�`l�>��E壾]Ȧ�8r�YX���h��8!Z��;p�;ǂ���*�a����OGd�(͘E�b��Jy.:�j������s��s����u��Pd	U���!�򀬠<{������.�8|A����D�����j�l���˨�Х�@T+uٝ��>�4Wk����:�x�%�mO�_c
����S;��"1��oy���lM~�G�ĵ�����AT�p&_�������J���|i��kv�f>���G����s|Ջ�cU��㯉��H��k�q�X�f���A������aŦaC���x�o�n�	�.#_�wԺ���N�c�1�ȨU\n`<�+�ڦi���INg�@4l� ��Dڍ���U�[�A�������0}��r����ԩ�繏ӥutv$ϭ@VU|��h6�5-԰[,x�7T���O�'�����x�����o�ؿ���L�y��3&��BQ8G�@�C���:�s���!��d;(p|Kn�B��uJW��<����ܱG�W�����"*��������NA�A�.��~B�7��Q˖�+!��ubg��T��Ă�o)6��)���~X�54,�G��������l����&Y�L�i6��!�8��.�o�o�E�Pa8��9�=�Z����I}��CǄ���b-2�|��k	%d͑	&�����vh�,��nK��x������n-�{l����¿jb���ħ�=�#����7K�/�J�������ʑ)J�Gt:�P�����4��(��*�4v��eJ���9JSF�(��&e*#ߺS"�0��[��3�L3��Od�0�@/�;F�~{Z�ȮƳ���M��ͭ��1��)\��TNV2iYQ�ɒ�&k)
2*)�dY�d�d�l&iY���2�z2��SrF��c����/ÿ� \h�����M��+��+ݪ��|kk�C`a?:����O�Q�u0�&>}~O�W4v���Զ�ʋ-$�E�&���m�^��=�r�A��_�&�;b���[b�}E&��^̍�mK���)��WXB^˺_�6��K��ˍ�J�ݐ�Wk�]��;/��Wn��`�;d�������\��=���=��q�uԤ��:_	e��X�*�����H�I���>��D���n�k'ۮ�k[J�-��nr��x^��B��Qh���������&�B�%b!/J5d�b뉠���'Մz�1g�y��w����b-ߨK�Εo��d2��,Ʌ�$�Z�V	w[>�'q�H"���ݼm{�7�t���-_���R��굂T����~�U���]m��v�i�-tGu�Զ�<fB���mx&����8b���mw����s����rs�q��N~��Jy~ݦ�զ�T���\�sY�]�a��a�)��C.�a]�dӅ/�pjw���S藔�A�.we����;����'������a%�r��Z�{��܇�|i����"��h#�g�u���͆�S�y2�X��p���n����<ԝI4��&������-�����o��<(;�X��f��@���L�R��?*E�4�J�������;}���bXIEv���q���,02��ql�w0w��in��Mx��.�3y�A��c��H`Y���F�/fǜ�����n�w��� 嶝U������/@� ��	�<�����m��m	������|=����ٶ�>b�3�'�GM}\�pW��<��}X���og�aT�PM�n�\�����0=�̛2�*��:pf/�E�P����AⓃ�����L<�'LsF�i�h�`[+��nfj�b����V����)�h�^�����33��/;7F�����������M�.����P�~�ڿ4��]Ϟ��czm��	�ϰ�i�B�O�:��C�	��a&�p){��<T�\d#[����9�Y�=�q��a����pq�3.`
�|3������?�E@e��G���߃����V����+.T�6b���:�t4,`�P�p�G��F�%��H1�1cT��g��%�8'-�4�s�6�yt��b����L�E!~�q����T�+.��]Yo�@~��m�RU@�؀��C�����/Qc��@���;����&�#��{!ػ���w�������Kh<C|�
U������<In�T}7-/2/�)Y�j��V������}99��� ��@��������$"q4�nL���"+#��|�ޗ��&,�fx
&�I�5Ό�f-�R} 3Ch��+L�<��e���ë���)�.�1���@�_�V$=#�1�bDS_\b�s1M-��T,k�d" ǎ�8(Ŕ��QC��@�l3��oҪ4�̹��Ƌ���Ef`���$�(�Xb�.j�K��M	o�L���l���t�Z�\.i��.�/���e����|��;�m[?3�2_�C��'�&��r45��T��g���a�;�A�wm���Q�����t��Pځ�فt������}�y�U���w/\/��a?Ze���N��2��2s�\=�t\�i.5w�����t4�C�2�V\}
���iP	�F�Cݺ�7���%��	�F�ky��_m�e��h��H�����jDYo�[�R�UQB�z7���á�v?�#sg����R��v�x��wfwU��:�j9���� �����~�WxL���Q����W0�o�Dt�
���A_�v��蓜\�1����.���VW�4 ��D�h�,�Nn�50[�Y�6�Wr��Z�K�����K��S#�H����ƚ��6�O���>�@'N/n�eL�(3�X�3�cP��s~���Q:=��3���`0��`0��`0�FtB 0 