#!/bin/sh -e

###
# Copyright (c) 2015-2016, Antoine Le Gonidec
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# This software is provided by the copyright holders and contributors "as is"
# and any express or implied warranties, including, but not limited to, the
# implied warranties of merchantability and fitness for a particular purpose
# are disclaimed. In no event shall the copyright holder or contributors be
# liable for any direct, indirect, incidental, special, exemplary, or
# consequential damages (including, but not limited to, procurement of
# substitute goods or services; loss of use, data, or profits; or business
# interruption) however caused and on any theory of liability, whether in
# contract, strict liability, or tort (including negligence or otherwise)
# arising in any way out of the use of this software, even if advised of the
# possibility of such damage.
###

###
# conversion script for the Star Wars Knights of the Old Republic II installer sold on GOG.com
# build a .deb package from the Windows installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20160919.3

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unar'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='star-wars-kotor-2'
GAME_ID_SHORT='kotor2'
GAME_NAME='Star Wars Knights of the Old Republic II: The Sith Lords'

GAME_ARCHIVE1='setup_sw_kotor2_2.0.0.3-1.bin'
GAME_ARCHIVE1_MD5='bbedad0d349a653a1502f2b9f4c207fc'
GAME_ARCHIVE1_FULLSIZE='4700000'
GAME_ARCHIVE2='setup_sw_kotor2_french_2.0.0.3-1.bin'
GAME_ARCHIVE2_MD5='27a4f0ba820bc66f53aa5117684917cf'
GAME_ARCHIVE2_FULLSIZE='4600000'
PKG_REVISION='gog2.0.0.3'

INSTALLER_PATH='game'
INSTALLER_JUNK='./goggame-* ./saves ./webcache.zip'
INSTALLER_DOC='./*.pdf ./update1_0b.txt ./links'
INSTALLER_GAME_PKG1='./*.exe ../support/app/*.ini'
INSTALLER_GAME_PKG2='./dialog.tlk lips/001ebo_loc.mod lips/002ebo_loc.mod lips/003ebo_loc.mod lips/004ebo_loc.mod lips/005ebo_loc.mod lips/006ebo_loc.mod lips/007ebo_loc.mod lips/101per_loc.mod lips/102per_loc.mod lips/103per_loc.mod lips/104per_loc.mod lips/105per_loc.mod lips/106per_loc.mod lips/107per_loc.mod lips/151har_loc.mod lips/152har_loc.mod lips/153har_loc.mod lips/201tel_loc.mod lips/202tel_loc.mod lips/203tel_loc.mod lips/204tel_loc.mod lips/205tel_loc.mod lips/207tel_loc.mod lips/208tel_loc.mod lips/209tel_loc.mod lips/220tel_loc.mod lips/221tel_loc.mod lips/222tel_loc.mod lips/231tel_loc.mod lips/232tel_loc.mod lips/233tel_loc.mod lips/261tel_loc.mod lips/262tel_loc.mod lips/301nar_loc.mod lips/302nar_loc.mod lips/303nar_loc.mod lips/304nar_loc.mod lips/305nar_loc.mod lips/306nar_loc.mod lips/351nar_loc.mod lips/352nar_loc.mod lips/401dxn_loc.mod lips/402dxn_loc.mod lips/403dxn_loc.mod lips/410dxn_loc.mod lips/411dxn_loc.mod lips/501ond_loc.mod lips/502ond_loc.mod lips/503ond_loc.mod lips/504ond_loc.mod lips/506ond_loc.mod lips/511ond_loc.mod lips/512ond_loc.mod lips/601dan_loc.mod lips/602dan_loc.mod lips/604dan_loc.mod lips/605dan_loc.mod lips/610dan_loc.mod lips/650dan_loc.mod lips/701kor_loc.mod lips/702kor_loc.mod lips/710kor_loc.mod lips/711kor_loc.mod lips/851nih_loc.mod lips/852nih_loc.mod lips/853nih_loc.mod lips/901mal_loc.mod lips/902mal_loc.mod lips/903mal_loc.mod lips/904mal_loc.mod lips/905mal_loc.mod lips/906mal_loc.mod lips/907mal_loc.mod lips/950cor_loc.mod lips/localization.mod movies/kremov01.bik movies/permov01.bik movies/scnmov01.bik movies/trailer.bik override/001comp_voc001.wav override/001comp_voc002.wav override/001comp_voc003.wav override/001comp_voc004.wav override/001comp_voc005.wav override/001comp_voc006.wav override/101pervoice001.wav override/101pervoice002.wav override/101pervoice003.wav override/101pervoice004.wav override/101pervoice005.wav override/101pervoice006.wav override/101pervoice007.wav override/101pervoice008.wav override/abilities_p.gui override/character_p.gui override/classsel_p.gui override/computer_p.gui override/dialogfont10x10.tpc override/equip_p.gui override/inventory_p.gui override/journal_p.gui override/keymap.2da override/lbl_iplotxp.tpc override/legal.tpc override/maincg_p.gui override/maininterface_p.gui override/mi8x6_p.gui override/mipc28x6_p.gui override/partyselect_p.gui override/saveload_p.gui override/tooltip10x8_p.gui override/tooltip12x9_p.gui override/tooltip16x12_p.gui override/tooltip6x4_p.gui override/tooltip8x6_p.gui override/uibut_lstick.tpc override/uibut_ltrig.tpc override/uibut_rstick.tpc override/uibut_rstick_ud.tpc override/uibut_rtrig.tpc override/upgradesel_p.gui ./rims streamsounds/a_aliengen_atk.wav streamsounds/a_aliengen_bat.wav streamsounds/a_aliengen_dam.wav streamsounds/a_aliengen_die.wav streamsounds/a_bith_atk.wav streamsounds/a_bith_bat.wav streamsounds/a_bith_dam.wav streamsounds/a_bith_die.wav streamsounds/a_duro_atk.wav streamsounds/a_duro_bat.wav streamsounds/a_duro_dam.wav streamsounds/a_duro_die.wav streamsounds/a_gran_atk.wav streamsounds/a_gran_bat.wav streamsounds/a_gran_dam.wav streamsounds/a_gran_die.wav streamsounds/a_hutt_atk.wav streamsounds/a_hutt_bat.wav streamsounds/a_hutt_dam.wav streamsounds/a_hutt_die.wav streamsounds/a_nikto_atk.wav streamsounds/a_nikto_bat.wav streamsounds/a_nikto_dam.wav streamsounds/a_nikto_die.wav streamsounds/a_rodfem_atk.wav streamsounds/a_rodfem_bat.wav streamsounds/a_rodfem_dam.wav streamsounds/a_rodfem_die.wav streamsounds/a_rodmale_atk.wav streamsounds/a_rodmale_bat.wav streamsounds/a_rodmale_dam.wav streamsounds/a_rodmale_die.wav streamsounds/a_rodtough_atk.wav streamsounds/a_rodtough_bat.wav streamsounds/a_rodtough_dam.wav streamsounds/a_rodtough_die.wav streamsounds/a_trando_atk.wav streamsounds/a_trando_bat.wav streamsounds/a_trando_dam.wav streamsounds/a_trando_die.wav streamsounds/a_weequay_atk.wav streamsounds/a_weequay_bat.wav streamsounds/a_weequay_dam.wav streamsounds/a_weequay_die.wav streamsounds/n_mndlorian_bat2.wav streamsounds/p_atton_atk1.wav streamsounds/p_atton_atk2.wav streamsounds/p_atton_atk3.wav streamsounds/p_atton_bat1.wav streamsounds/p_atton_bat2.wav streamsounds/p_atton_bat3.wav streamsounds/p_atton_bat4.wav streamsounds/p_atton_bat5.wav streamsounds/p_atton_bat6.wav streamsounds/p_atton_block.wav streamsounds/p_atton_crit.wav streamsounds/p_atton_dead.wav streamsounds/p_atton_dmin.wav streamsounds/p_atton_flock.wav streamsounds/p_atton_hit1.wav streamsounds/p_atton_hit2.wav streamsounds/p_atton_lmin.wav streamsounds/p_atton_low.wav streamsounds/p_atton_pois.wav streamsounds/p_atton_rprty.wav streamsounds/p_atton_slct1.wav streamsounds/p_atton_slct2.wav streamsounds/p_atton_slct3.wav streamsounds/p_atton_slock.wav streamsounds/p_atton_sprty.wav streamsounds/p_atton_srch.wav streamsounds/p_atton_stlh.wav streamsounds/p_atton_tia.wav streamsounds/p_baodur_atk1.wav streamsounds/p_baodur_atk2.wav streamsounds/p_baodur_atk3.wav streamsounds/p_baodur_bat1.wav streamsounds/p_baodur_bat2.wav streamsounds/p_baodur_bat3.wav streamsounds/p_baodur_bat4.wav streamsounds/p_baodur_bat5.wav streamsounds/p_baodur_bat6.wav streamsounds/p_baodur_block.wav streamsounds/p_baodur_crit.wav streamsounds/p_baodur_dead.wav streamsounds/p_baodur_dmin.wav streamsounds/p_baodur_flock.wav streamsounds/p_baodur_hit1.wav streamsounds/p_baodur_hit2.wav streamsounds/p_baodur_lmin.wav streamsounds/p_baodur_low.wav streamsounds/p_baodur_pois.wav streamsounds/p_baodur_rprty.wav streamsounds/p_baodur_slct1.wav streamsounds/p_baodur_slct2.wav streamsounds/p_baodur_slct3.wav streamsounds/p_baodur_slock.wav streamsounds/p_baodur_sprty.wav streamsounds/p_baodur_srch.wav streamsounds/p_baodur_stlh.wav streamsounds/p_baodur_tia.wav streamsounds/p_disciple_atk1.wav streamsounds/p_disciple_atk2.wav streamsounds/p_disciple_atk3.wav streamsounds/p_disciple_bat1.wav streamsounds/p_disciple_bat2.wav streamsounds/p_disciple_bat3.wav streamsounds/p_disciple_bat4.wav streamsounds/p_disciple_bat5.wav streamsounds/p_disciple_bat6.wav streamsounds/p_disciple_block.wav streamsounds/p_disciple_crit.wav streamsounds/p_disciple_dead.wav streamsounds/p_disciple_dmin.wav streamsounds/p_disciple_flock.wav streamsounds/p_disciple_hit1.wav streamsounds/p_disciple_hit2.wav streamsounds/p_disciple_lmin.wav streamsounds/p_disciple_low.wav streamsounds/p_disciple_pois.wav streamsounds/p_disciple_rprty.wav streamsounds/p_disciple_slct1.wav streamsounds/p_disciple_slct2.wav streamsounds/p_disciple_slct3.wav streamsounds/p_disciple_slock.wav streamsounds/p_disciple_sprty.wav streamsounds/p_disciple_srch.wav streamsounds/p_disciple_stlh.wav streamsounds/p_disciple_tia.wav streamsounds/p_g0t0_atk1.wav streamsounds/p_g0t0_atk2.wav streamsounds/p_g0t0_atk3.wav streamsounds/p_g0t0_bat1.wav streamsounds/p_g0t0_bat2.wav streamsounds/p_g0t0_bat3.wav streamsounds/p_g0t0_bat4.wav streamsounds/p_g0t0_bat5.wav streamsounds/p_g0t0_bat6.wav streamsounds/p_g0t0_block.wav streamsounds/p_g0t0_crit.wav streamsounds/p_g0t0_dead.wav streamsounds/p_g0t0_dmin.wav streamsounds/p_g0t0_flock.wav streamsounds/p_g0t0_hit1.wav streamsounds/p_g0t0_hit2.wav streamsounds/p_g0t0_lmin.wav streamsounds/p_g0t0_low.wav streamsounds/p_g0t0_pois.wav streamsounds/p_g0t0_rprty.wav streamsounds/p_g0t0_slct1.wav streamsounds/p_g0t0_slct2.wav streamsounds/p_g0t0_slct3.wav streamsounds/p_g0t0_slock.wav streamsounds/p_g0t0_sprty.wav streamsounds/p_g0t0_srch.wav streamsounds/p_g0t0_stlh.wav streamsounds/p_g0t0_tia.wav streamsounds/p_hand_atk1.wav streamsounds/p_hand_atk2.wav streamsounds/p_hand_atk3.wav streamsounds/p_hand_bat1.wav streamsounds/p_hand_bat2.wav streamsounds/p_hand_bat3.wav streamsounds/p_hand_bat4.wav streamsounds/p_hand_bat5.wav streamsounds/p_hand_bat6.wav streamsounds/p_hand_block.wav streamsounds/p_hand_crit.wav streamsounds/p_hand_dead.wav streamsounds/p_hand_dmin.wav streamsounds/p_hand_flock.wav streamsounds/p_hand_hit1.wav streamsounds/p_hand_hit2.wav streamsounds/p_hand_lmin.wav streamsounds/p_hand_low.wav streamsounds/p_hand_pois.wav streamsounds/p_hand_rprty.wav streamsounds/p_hand_slct1.wav streamsounds/p_hand_slct2.wav streamsounds/p_hand_slct3.wav streamsounds/p_hand_slock.wav streamsounds/p_hand_sprty.wav streamsounds/p_hand_srch.wav streamsounds/p_hand_stlh.wav streamsounds/p_hand_tia.wav streamsounds/p_hk47_atk1.wav streamsounds/p_hk47_atk2.wav streamsounds/p_hk47_atk3.wav streamsounds/p_hk47_bat1.wav streamsounds/p_hk47_bat2.wav streamsounds/p_hk47_bat3.wav streamsounds/p_hk47_bat4.wav streamsounds/p_hk47_bat5.wav streamsounds/p_hk47_bat6.wav streamsounds/p_hk47_block.wav streamsounds/p_hk47_crit.wav streamsounds/p_hk47_dead.wav streamsounds/p_hk47_dmin.wav streamsounds/p_hk47_flock.wav streamsounds/p_hk47_hit1.wav streamsounds/p_hk47_hit2.wav streamsounds/p_hk47_lmin.wav streamsounds/p_hk47_low.wav streamsounds/p_hk47_pois.wav streamsounds/p_hk47_rprty.wav streamsounds/p_hk47_slct1.wav streamsounds/p_hk47_slct2.wav streamsounds/p_hk47_slct3.wav streamsounds/p_hk47_slock.wav streamsounds/p_hk47_sprty.wav streamsounds/p_hk47_srch.wav streamsounds/p_hk47_stlh.wav streamsounds/p_hk47_tia.wav streamsounds/p_kreia_atk1.wav streamsounds/p_kreia_atk2.wav streamsounds/p_kreia_atk3.wav streamsounds/p_kreia_bat1.wav streamsounds/p_kreia_bat2.wav streamsounds/p_kreia_bat3.wav streamsounds/p_kreia_bat4.wav streamsounds/p_kreia_bat5.wav streamsounds/p_kreia_bat6.wav streamsounds/p_kreia_block.wav streamsounds/p_kreia_crit.wav streamsounds/p_kreia_dead.wav streamsounds/p_kreia_dmin.wav streamsounds/p_kreia_flock.wav streamsounds/p_kreia_hit1.wav streamsounds/p_kreia_hit2.wav streamsounds/p_kreia_lmin.wav streamsounds/p_kreia_low.wav streamsounds/p_kreia_pois.wav streamsounds/p_kreia_rprty.wav streamsounds/p_kreia_slct1.wav streamsounds/p_kreia_slct2.wav streamsounds/p_kreia_slct3.wav streamsounds/p_kreia_slock.wav streamsounds/p_kreia_sprty.wav streamsounds/p_kreia_srch.wav streamsounds/p_kreia_stlh.wav streamsounds/p_kreia_tia.wav streamsounds/p_mand_atk1.wav streamsounds/p_mand_atk2.wav streamsounds/p_mand_atk3.wav streamsounds/p_mand_bat1.wav streamsounds/p_mand_bat2.wav streamsounds/p_mand_bat3.wav streamsounds/p_mand_bat4.wav streamsounds/p_mand_bat5.wav streamsounds/p_mand_bat6.wav streamsounds/p_mand_block.wav streamsounds/p_mand_crit.wav streamsounds/p_mand_dead.wav streamsounds/p_mand_dmin.wav streamsounds/p_mand_flock.wav streamsounds/p_mand_hit1.wav streamsounds/p_mand_hit2.wav streamsounds/p_mand_lmin.wav streamsounds/p_mand_low.wav streamsounds/p_mand_pois.wav streamsounds/p_mand_rprty.wav streamsounds/p_mand_slct1.wav streamsounds/p_mand_slct2.wav streamsounds/p_mand_slct3.wav streamsounds/p_mand_slock.wav streamsounds/p_mand_sprty.wav streamsounds/p_mand_srch.wav streamsounds/p_mand_stlh.wav streamsounds/p_mand_tia.wav streamsounds/p_mira_atk1.wav streamsounds/p_mira_atk2.wav streamsounds/p_mira_atk3.wav streamsounds/p_mira_bat1.wav streamsounds/p_mira_bat2.wav streamsounds/p_mira_bat3.wav streamsounds/p_mira_bat4.wav streamsounds/p_mira_bat5.wav streamsounds/p_mira_bat6.wav streamsounds/p_mira_block.wav streamsounds/p_mira_crit.wav streamsounds/p_mira_dead.wav streamsounds/p_mira_dmin.wav streamsounds/p_mira_flock.wav streamsounds/p_mira_hit1.wav streamsounds/p_mira_hit2.wav streamsounds/p_mira_lmin.wav streamsounds/p_mira_low.wav streamsounds/p_mira_pois.wav streamsounds/p_mira_rprty.wav streamsounds/p_mira_slct1.wav streamsounds/p_mira_slct2.wav streamsounds/p_mira_slct3.wav streamsounds/p_mira_slock.wav streamsounds/p_mira_sprty.wav streamsounds/p_mira_srch.wav streamsounds/p_mira_stlh.wav streamsounds/p_mira_tia.wav streamsounds/p_visas_atk1.wav streamsounds/p_visas_atk2.wav streamsounds/p_visas_atk3.wav streamsounds/p_visas_bat1.wav streamsounds/p_visas_bat2.wav streamsounds/p_visas_bat3.wav streamsounds/p_visas_bat4.wav streamsounds/p_visas_bat5.wav streamsounds/p_visas_bat6.wav streamsounds/p_visas_block.wav streamsounds/p_visas_crit.wav streamsounds/p_visas_dead.wav streamsounds/p_visas_dmin.wav streamsounds/p_visas_flock.wav streamsounds/p_visas_hit1.wav streamsounds/p_visas_hit2.wav streamsounds/p_visas_lmin.wav streamsounds/p_visas_low.wav streamsounds/p_visas_pois.wav streamsounds/p_visas_rprty.wav streamsounds/p_visas_slct1.wav streamsounds/p_visas_slct2.wav streamsounds/p_visas_slct3.wav streamsounds/p_visas_slock.wav streamsounds/p_visas_sprty.wav streamsounds/p_visas_srch.wav streamsounds/p_visas_stlh.wav streamsounds/p_visas_tia.wav streamvoice/001 streamvoice/002 streamvoice/003 streamvoice/004 streamvoice/101 streamvoice/102 streamvoice/103 streamvoice/104 streamvoice/105/admoff streamvoice/105/coordead streamvoice/105/coorta streamvoice/105/dockoff streamvoice/105/sien/105sien012.wav streamvoice/105/sien/105sien013.wav streamvoice/106 streamvoice/107 streamvoice/151 streamvoice/152 streamvoice/153 streamvoice/201 streamvoice/202 streamvoice/203/200merc streamvoice/203/202czerf streamvoice/203/202czerm streamvoice/203/203atton/203203atton001.wav streamvoice/203/203atton/203203atton003.wav streamvoice/203/203atton/203203atton004.wav streamvoice/203/203atton/203203atton005.wav streamvoice/203/203atton/203203atton006.wav streamvoice/203/203atton/203203atton007.wav streamvoice/203/203atton/203203atton008.wav streamvoice/203/203atton/203203atton009.wav streamvoice/203/203atton/203203atton010.wav streamvoice/203/203atton/203203atton011.wav streamvoice/203/203atton/203203atton012.wav streamvoice/203/203atton/203203atton013.wav streamvoice/203/203atton/203203atton014.wav streamvoice/203/203atton/203203atton015.wav streamvoice/203/203atton/203203atton017.wav streamvoice/203/203atton/203203atton018.wav streamvoice/203/203atton/203203atton019.wav streamvoice/203/203atton/203203atton020.wav streamvoice/203/203atton/203203atton021.wav streamvoice/203/203atton/203203atton022.wav streamvoice/203/203atton/203203atton023.wav streamvoice/203/203atton/203203atton024.wav streamvoice/203/203atton/203203atton025.wav streamvoice/203/203atton/203203atton026.wav streamvoice/203/203atton/203203atton027.wav streamvoice/203/203atton/203203atton028.wav streamvoice/203/203atton/203203atton029.wav streamvoice/203/203atton/203203atton030.wav streamvoice/203/203atton/203203atton031.wav streamvoice/203/203atton/203203atton032.wav streamvoice/203/203atton/203203atton033.wav streamvoice/203/203atton/203203atton034.wav streamvoice/203/203atton/203203atton035.wav streamvoice/203/203atton/203203atton036.wav streamvoice/203/203atton/203203atton037.wav streamvoice/203/203atton/203203atton038.wav streamvoice/203/203atton/203203atton039.wav streamvoice/203/203atton/203203atton040.wav streamvoice/203/203atton/203203atton041.wav streamvoice/203/203atton/203203atton042.wav streamvoice/203/203atton/203203atton043.wav streamvoice/203/203atton/203203atton044.wav streamvoice/203/203atton/203203atton045.wav streamvoice/203/203atton/203203atton046.wav streamvoice/203/203atton/203203atton047.wav streamvoice/203/203atton/203203atton048.wav streamvoice/203/203atton/203203atton049.wav streamvoice/203/203atton/203203atton050.wav streamvoice/203/203atton/203203atton051.wav streamvoice/203/203atton/203203atton052.wav streamvoice/203/203atton/203203atton053.wav streamvoice/203/203atton/203203atton054.wav streamvoice/203/203atton/203203atton055.wav streamvoice/203/203atton/203203atton056.wav streamvoice/203/203atton/203203atton057.wav streamvoice/203/203b4d4 streamvoice/203/203bao streamvoice/203/203_baodur streamvoice/203/203grenn streamvoice/203/203habat streamvoice/203/203kreia streamvoice/203/203lorso streamvoice/203/203luxa streamvoice/203/203moza/203203moza001.wav streamvoice/203/203moza/203203moza002.wav streamvoice/203/203moza/203203moza003.wav streamvoice/203/203moza/203203moza021.wav streamvoice/203/203moza/203203moza022.wav streamvoice/203/203moza/203203moza023.wav streamvoice/203/203moza/203203moza024.wav streamvoice/203/203moza/203203moza025.wav streamvoice/203/203moza/203203moza026.wav streamvoice/203/203moza/203203moza027.wav streamvoice/203/203moza/203203moza028.wav streamvoice/203/203moza/203203moza029.wav streamvoice/203/203moza/203203moza030.wav streamvoice/203/203moza/203203moza031.wav streamvoice/203/203moza/203203moza051.wav streamvoice/203/203moza/203203moza082.wav streamvoice/203/203slusk streamvoice/203/203t1n12 streamvoice/203/203ts2a streamvoice/203/203tsf2a streamvoice/203/203vula streamvoice/203/batono streamvoice/203/civilian streamvoice/203/czerka2 streamvoice/203/czerkag streamvoice/203/czerkag2 streamvoice/203/falt streamvoice/203/meeting streamvoice/203/mercbat streamvoice/203/mercfp streamvoice/203/merclead streamvoice/203/rodkill streamvoice/204/204habat streamvoice/204/204moza/204204moza060.wav streamvoice/204/ond_dip streamvoice/204/tsf_med streamvoice/207 streamvoice/220 streamvoice/221 streamvoice/222 streamvoice/231 streamvoice/232 streamvoice/233 streamvoice/261 streamvoice/262/262atton streamvoice/262/262bdcg streamvoice/262/262kreia streamvoice/262/atrend1 streamvoice/262/atrend2 streamvoice/262/atrend3 streamvoice/262/atrend4 streamvoice/262/atrhand streamvoice/262/atris streamvoice/262/atriscs1 streamvoice/262/atriscs3 streamvoice/262/atrissis streamvoice/262/fight streamvoice/262/handend streamvoice/262/holorec/262holorec001.wav streamvoice/262/holorec/262holorec005.wav streamvoice/262/holorec/262holorec007.wav streamvoice/262/holorec/262holorec008.wav streamvoice/262/holorec/262holorec009.wav streamvoice/262/holorec/262holorec010.wav streamvoice/262/holorec/262holorec011.wav streamvoice/262/holorec/262holorec012.wav streamvoice/262/holorec/262holorec013.wav streamvoice/262/holorec/262holorec014.wav streamvoice/262/holorec/262holorec015.wav streamvoice/262/holorec/262holorec016.wav streamvoice/262/holorec/262holorec017.wav streamvoice/262/holorec/262holorec018.wav streamvoice/262/holorec/262holorec019.wav streamvoice/262/holorec/262holorec020.wav streamvoice/262/holorec/262holorec021.wav streamvoice/262/holorec/262holorec022.wav streamvoice/262/holorec/262holorec023.wav streamvoice/262/holorec/262holorec024.wav streamvoice/262/holorec/262holorec025.wav streamvoice/262/holorec/262holorec026.wav streamvoice/262/holorec/262holorec027.wav streamvoice/262/holorec/262holorec028.wav streamvoice/262/holorec/262holorec029.wav streamvoice/262/holorec/262holorec030.wav streamvoice/262/holorec/262holorec031.wav streamvoice/262/holorec/262holorec032.wav streamvoice/262/holorec/262holorec033.wav streamvoice/262/holorec/262holorec034.wav streamvoice/262/holorec/262holorec035.wav streamvoice/262/holorec/262holorec036.wav streamvoice/262/holorec/262holorec037.wav streamvoice/262/holorec/262holorec038.wav streamvoice/262/holorec/262holorec039.wav streamvoice/262/holorec/262holorec040.wav streamvoice/262/holorec/262holorec051.wav streamvoice/262/holorec/262holorec052.wav streamvoice/262/holorec/262holorec053.wav streamvoice/262/holorec/262holorec058.wav streamvoice/262/holorec/262holorec059.wav streamvoice/262/holorec/262holorec060.wav streamvoice/262/holorec/262holorec061.wav streamvoice/262/holorec/262holorec062.wav streamvoice/262/holorec/262holorec063.wav streamvoice/262/holorec/262holorec064.wav streamvoice/262/holorec/262holorec065.wav streamvoice/262/holorec/262holorec066.wav streamvoice/262/holorec/262holorec067.wav streamvoice/262/holorec/262holorec068.wav streamvoice/262/holorec/262holorec069.wav streamvoice/262/holorec/262holorec070.wav streamvoice/262/holorec/262holorec071.wav streamvoice/262/kreatris streamvoice/262/krehand1 streamvoice/262/medchamdoor streamvoice/262/meddoor streamvoice/262/nihilus streamvoice/262/siscut1 streamvoice/262/sisend streamvoice/262/sister streamvoice/298 streamvoice/299/alinholo streamvoice/299/hk47hk50 streamvoice/299/hk47hk51 streamvoice/299/hk50 streamvoice/299/hk51 streamvoice/299/inttrain streamvoice/299/mertrain streamvoice/301/arrival streamvoice/301/attontmp streamvoice/301/attstop streamvoice/301/attwarn streamvoice/301/attwarn2 streamvoice/301/azanti streamvoice/301/bartend streamvoice/301/borna streamvoice/301/c9t9 streamvoice/301/dahnis streamvoice/301/drdplay streamvoice/301/duroamb streamvoice/301/gambler streamvoice/301/gamblerf streamvoice/301/kodin streamvoice/301/kreiare streamvoice/301/kreiatch streamvoice/301/miratch streamvoice/301/nscommal streamvoice/301/oondar streamvoice/301/quello streamvoice/301/ratrin streamvoice/301/recutarr streamvoice/301/refenc streamvoice/301/ref_mira streamvoice/301/refugee streamvoice/301/refugee2 streamvoice/301/refugee3 streamvoice/301/refugee30 streamvoice/301/rutum streamvoice/301/tienn streamvoice/301/twidomo streamvoice/301/twindead streamvoice/301/visquis/301visquis001.wav streamvoice/301/visquis/301visquis002.wav streamvoice/301/visquis/301visquis003.wav streamvoice/301/visquis/301visquis007.wav streamvoice/301/visquis/301visquis009.wav streamvoice/301/visquis/301visquis010.wav streamvoice/301/visquis/301visquis011.wav streamvoice/301/visquis/301visquis012.wav streamvoice/301/visquis/301visquis013.wav streamvoice/301/visquis/301visquis014.wav streamvoice/301/visquis/301visquis015.wav streamvoice/301/visquis/301visquis016.wav streamvoice/301/visquis/301visquis017.wav streamvoice/301/visquis/301visquis018.wav streamvoice/301/visquis/301visquis019.wav streamvoice/301/visquis/301visquis020.wav streamvoice/301/visquis/301visquis021.wav streamvoice/301/visquis/301visquis022.wav streamvoice/301/visquis/301visquis023.wav streamvoice/301/visquis/301visquis024.wav streamvoice/301/visquis/301visquis025.wav streamvoice/301/visquis/301visquis026.wav streamvoice/301/visquis/301visquis027.wav streamvoice/301/visquis/301visquis028.wav streamvoice/301/visquis/301visquis029.wav streamvoice/301/visquis/301visquis030.wav streamvoice/301/visquis/301visquis031.wav streamvoice/301/visquis/301visquis032.wav streamvoice/301/vossk streamvoice/301/zezkaiel streamvoice/302/aaida streamvoice/302/adana streamvoice/302/airtaxi streamvoice/302/geriel streamvoice/302/hussef/302hussef001.wav streamvoice/302/hussef/302hussef008.wav streamvoice/302/hussef/302hussef009.wav streamvoice/302/hussef/302hussef010.wav streamvoice/302/hussef/302hussef011.wav streamvoice/302/hussef/302hussef012.wav streamvoice/302/hussef/302hussef013.wav streamvoice/302/hussef/302hussef014.wav streamvoice/302/hussef/302hussef015.wav streamvoice/302/hussef/302hussef016.wav streamvoice/302/hussef/302hussef017.wav streamvoice/302/hussef/302hussef018.wav streamvoice/302/hussef/302hussef019.wav streamvoice/302/hussef/302hussef020.wav streamvoice/302/hussef/302hussef021.wav streamvoice/302/hussef/302hussef022.wav streamvoice/302/hussef/302hussef023.wav streamvoice/302/hussef/302hussef024.wav streamvoice/302/hussef/302hussef025.wav streamvoice/302/hussef/302hussef026.wav streamvoice/302/hussef/302hussef027.wav streamvoice/302/hussef/302hussef028.wav streamvoice/302/hussef/302hussef029.wav streamvoice/302/hussef/302hussef030.wav streamvoice/302/hussef/302hussef031.wav streamvoice/302/hussef/302hussef032.wav streamvoice/302/hussef/302hussef033.wav streamvoice/302/hussef/302hussef034.wav streamvoice/302/hussef/302hussef035.wav streamvoice/302/hussef/302hussef036.wav streamvoice/302/hussef/302hussef037.wav streamvoice/302/hussef/302hussef038.wav streamvoice/302/hussef/302hussef039.wav streamvoice/302/hussef/302hussef040.wav streamvoice/302/hussef/302hussef041.wav streamvoice/302/hussef/302hussef042.wav streamvoice/302/hussef/302hussef043.wav streamvoice/302/hussef/302hussef044.wav streamvoice/302/hussef/302hussef045.wav streamvoice/302/hussef/302hussef046.wav streamvoice/302/hussef/302hussef047.wav streamvoice/302/hussef/302hussef048.wav streamvoice/302/hussef/302hussef049.wav streamvoice/302/hussef/302hussef050.wav streamvoice/302/hussef/302hussef051.wav streamvoice/302/hussef/302hussef052.wav streamvoice/302/hussef/302hussef053.wav streamvoice/302/hussef/302hussef054.wav streamvoice/302/hussef/302hussef055.wav streamvoice/302/hussef/302hussef056.wav streamvoice/302/hussef/302hussef057.wav streamvoice/302/hussef/302hussef058.wav streamvoice/302/hussef/302hussef059.wav streamvoice/302/hussef/302hussef061.wav streamvoice/302/kahranna streamvoice/302/kehvhen streamvoice/302/nadaa streamvoice/302/odis streamvoice/302/refugeem streamvoice/302/serdoor streamvoice/302/serlead streamvoice/302/serthug streamvoice/302/serthug2 streamvoice/302/serthugb streamvoice/302/veteranm streamvoice/303 streamvoice/304 streamvoice/305 streamvoice/351 streamvoice/401 streamvoice/402 streamvoice/403 streamvoice/410 streamvoice/411/beast_ta streamvoice/411/cnpc_do streamvoice/411/cnpc_dse streamvoice/411/mira_e3 streamvoice/411/ritlead streamvoice/411/sithcapt streamvoice/411/xarga streamvoice/501 streamvoice/502/al_poli streamvoice/502/bostuco streamvoice/502/bounty1/502bounty1002.wav streamvoice/502/bounty1/502bounty1003.wav streamvoice/502/bounty1/502bounty1006.wav streamvoice/502/bounty2 streamvoice/502/cp_geles streamvoice/502/cp_replac streamvoice/502/cp_terly streamvoice/502/cp_tolas streamvoice/502/cp_trkd1 streamvoice/502/cp_trkd2 streamvoice/502/cs_vak_1 streamvoice/502/dhagon streamvoice/502/d_thug streamvoice/502/end_mark streamvoice/502/gen_citf streamvoice/502/gen_citi streamvoice/502/gen_sold streamvoice/502/gen_thug streamvoice/502/intgate streamvoice/502/mp_128 streamvoice/502/mp_anda streamvoice/502/mp_gegor streamvoice/502/mp_pgrd streamvoice/502/mp_ponla streamvoice/502/mp_riike streamvoice/502/nikko streamvoice/502/reporter streamvoice/502/riik_amb streamvoice/502/term_no streamvoice/502/term_so streamvoice/503 streamvoice/504 streamvoice/506 streamvoice/511 streamvoice/512 streamvoice/601/akkere streamvoice/601/azkul streamvoice/601/dillan streamvoice/601/g_milit2 streamvoice/601/g_militi streamvoice/601/mechanic streamvoice/601/olddroid streamvoice/601/pato streamvoice/601/saedhe streamvoice/601/sec_door streamvoice/601/vrook streamvoice/601/zherron/601zherron001.wav streamvoice/601/zherron/601zherron002.wav streamvoice/601/zherron/601zherron003.wav streamvoice/601/zherron/601zherron004.wav streamvoice/601/zherron/601zherron005.wav streamvoice/601/zherron/601zherron006.wav streamvoice/601/zherron/601zherron007.wav streamvoice/601/zherron/601zherron008.wav streamvoice/601/zherron/601zherron009.wav streamvoice/601/zherron/601zherron010.wav streamvoice/601/zherron/601zherron011.wav streamvoice/601/zherron/601zherron012.wav streamvoice/601/zherron/601zherron013.wav streamvoice/601/zherron/601zherron014.wav streamvoice/601/zherron/601zherron015.wav streamvoice/601/zherron/601zherron016.wav streamvoice/601/zherron/601zherron017.wav streamvoice/601/zherron/601zherron018.wav streamvoice/601/zherron/601zherron019.wav streamvoice/601/zherron/601zherron020.wav streamvoice/601/zherron/601zherron021.wav streamvoice/601/zherron/601zherron022.wav streamvoice/601/zherron/601zherron023.wav streamvoice/601/zherron/601zherron024.wav streamvoice/601/zherron/601zherron025.wav streamvoice/601/zherron/601zherron026.wav streamvoice/601/zherron/601zherron027.wav streamvoice/601/zherron/601zherron028.wav streamvoice/601/zherron/601zherron029.wav streamvoice/601/zherron/601zherron030.wav streamvoice/601/zherron/601zherron031.wav streamvoice/601/zherron/601zherron032.wav streamvoice/601/zherron/601zherron034.wav streamvoice/601/zherron/601zherron035.wav streamvoice/601/zherron/601zherron036.wav streamvoice/601/zherron/601zherron037.wav streamvoice/601/zherron/601zherron038.wav streamvoice/601/zherron/601zherron039.wav streamvoice/601/zherron/601zherron040.wav streamvoice/601/zherron/601zherron041.wav streamvoice/601/zherron/601zherron042.wav streamvoice/601/zherron/601zherron043.wav streamvoice/601/zherron/601zherron044.wav streamvoice/601/zherron/601zherron045.wav streamvoice/601/zherron/601zherron046.wav streamvoice/601/zherron/601zherron047.wav streamvoice/601/zherron/601zherron048.wav streamvoice/601/zherron/601zherron049.wav streamvoice/601/zherron/601zherron050.wav streamvoice/602 streamvoice/604 streamvoice/605 streamvoice/610 streamvoice/650 streamvoice/701 streamvoice/702 streamvoice/710 streamvoice/711 streamvoice/851/851dem streamvoice/851/851exp streamvoice/851/851mand streamvoice/851/851medit streamvoice/851/851tobin streamvoice/851/851visas streamvoice/851/851visdr streamvoice/852 streamvoice/853 streamvoice/901 streamvoice/902 streamvoice/903 streamvoice/904 streamvoice/907 streamvoice/950 streamvoice/a_a streamvoice/a_b streamvoice/a_d streamvoice/a_g streamvoice/a_h streamvoice/a_n streamvoice/a_r streamvoice/a_t streamvoice/avo/_bithcmn streamvoice/avo/_bithgre streamvoice/avo/_durocmn streamvoice/avo/_durogre streamvoice/avo/_genalnan streamvoice/avo/_genalncmn streamvoice/avo/_genalnque streamvoice/avo/_genalnscr streamvoice/avo/_genalnwou streamvoice/avo/_granan streamvoice/avo/_grancmn streamvoice/avo/_granque streamvoice/avo/_gransa streamvoice/avo/_huttan streamvoice/avo/_huttcmn streamvoice/avo/_huttgre streamvoice/avo/_hutthap streamvoice/avo/_huttmoc streamvoice/avo/_huttque streamvoice/avo/_huttsca streamvoice/avo/_niktan streamvoice/avo/_niktcmn streamvoice/avo/_niktque streamvoice/avo/_niktsa streamvoice/avo/_rodifan streamvoice/avo/_rodifcmn streamvoice/avo/_rodifgre streamvoice/avo/_rodifhap streamvoice/avo/_rodifmoc streamvoice/avo/_rodifple streamvoice/avo/_rodifque streamvoice/avo/_rodifsa streamvoice/avo/_rodifsca streamvoice/avo/_rodiman streamvoice/avo/_rodimcmn streamvoice/avo/_rodimgre streamvoice/avo/_rodimhap streamvoice/avo/_rodimmoc streamvoice/avo/_rodimple streamvoice/avo/_rodimque streamvoice/avo/_rodimsa streamvoice/avo/_rodimsca streamvoice/avo/_rodimtan streamvoice/avo/_rodimtcmn streamvoice/avo/_rodimtgre streamvoice/avo/_rodimthap streamvoice/avo/_rodimtmoc streamvoice/avo/_rodimtple streamvoice/avo/_rodimtque streamvoice/avo/_rodimtsa streamvoice/avo/_rodimtsca streamvoice/avo/_t3m4wou/avo_t3-m4_wounm1.wav streamvoice/avo/_t3m4wou/avo_t3-m4_wounm2.wav streamvoice/avo/_t3m4wou/avo_t3-m4_wounm3.wav streamvoice/avo/_t3m4wou/avo_t3-m4_wouns1.wav streamvoice/avo/_t3m4wou/avo_t3-m4_wouns2.wav streamvoice/avo/_t3m4wou/avo_t3-m4_wouns3.wav streamvoice/avo/_trodan streamvoice/avo/_trodcmn streamvoice/avo/_trodgre streamvoice/avo/_weeqan streamvoice/avo/_weeqcmn streamvoice/avo/_weeqque streamvoice/avo/_weeqsa streamvoice/a_w streamvoice/gbl/000level streamvoice/gbl/000react streamvoice/gbl/200comf streamvoice/gbl/200comm streamvoice/gbl/200tsff streamvoice/gbl/200tsfm streamvoice/gbl/atton streamvoice/gbl/attondem streamvoice/gbl/baodur streamvoice/gbl/disciple streamvoice/gbl/g0t0 streamvoice/gbl/handmaiden streamvoice/gbl/hk47 streamvoice/gbl/kreia streamvoice/gbl/lrn_form streamvoice/gbl/mandalore streamvoice/gbl/mira streamvoice/gbl/t3m4 streamvoice/gbl/visasmarr'
INSTALLER_GAME_PKG3='./movies'
INSTALLER_GAME_PKG4='./texturepacks'
INSTALLER_GAME_PKG5='./streammusic ./streamsounds ./streamvoice'
INSTALLER_GAME_PKG6='./*'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./override ./saves'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./swkotor2.exe'
APP1_ICON='./swkotor2.exe'
APP1_ICON_RES='32x32 48x48'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

APP2_ID="${GAME_ID}_config"
APP2_EXE='./swconfig.exe'
APP2_ICON='./swconfig.exe'
APP2_ICON_RES='32x32 48x48'
APP2_NAME="${GAME_NAME} - settings"
APP2_NAME_FR="${GAME_NAME} - réglages"
APP2_CAT='Settings'

PKG_VERSION='1.0b'

PKG1_ID="${GAME_ID}"
PKG1_VERSION="${PKG_VERSION}"
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-l10n"
PKG2_VERSION="${PKG_VERSION}"
PKG2_ARCH='all'
PKG2_CONFLICTS=''
PKG2_DEPS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME} - localization data
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG3_ID="${GAME_ID}-movies"
PKG3_VERSION="${PKG_VERSION}"
PKG3_ARCH='all'
PKG3_CONFLICTS=''
PKG3_DEPS=''
PKG3_RECS=''
PKG3_DESC="${GAME_NAME} - movies
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG4_ID="${GAME_ID}-textures"
PKG4_VERSION="${PKG_VERSION}"
PKG4_ARCH='all'
PKG4_CONFLICTS=''
PKG4_DEPS=''
PKG4_RECS=''
PKG4_DESC="${GAME_NAME} - textures
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG5_ID="${GAME_ID}-sounds"
PKG5_VERSION="${PKG_VERSION}"
PKG5_ARCH='all'
PKG5_CONFLICTS=''
PKG5_DEPS=''
PKG5_RECS=''
PKG5_DESC="${GAME_NAME} - sounds
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG6_ID="${GAME_ID}-data"
PKG6_VERSION="${PKG_VERSION}"
PKG6_ARCH='all'
PKG6_CONFLICTS=''
PKG6_DEPS=''
PKG6_RECS=''
PKG6_DESC="${GAME_NAME} - data
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG2_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG3_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG4_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG5_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG6_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"

# Load common functions

TARGET_LIB_VERSION='1.14'

if [ -z "${PLAYIT_LIB}" ]; then
	PLAYIT_LIB='./play-anything.sh'
fi

if ! [ -e "${PLAYIT_LIB}" ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\n'
	printf 'It must be placed in the same directory than this script.\n\n'
	exit 1
fi

LIB_VERSION="$(grep '^# library version' "${PLAYIT_LIB}" | cut -d' ' -f4 | cut -d'.' -f1,2)"

if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\n'
	printf 'It must be at least %s ' "${TARGET_LIB_VERSION}"
	printf 'but lower than %s.\n\n' "$((${TARGET_LIB_VERSION%.*}+1)).0"
	exit 1
fi

. "${PLAYIT_LIB}"

# Set extra variables

NO_ICON='0'

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard ${SCRIPT_DEPS_HARD}
check_deps_soft ${SCRIPT_DEPS_SOFT}

printf '\n'
set_target '2' 'gog.com'
case "$(basename ${GAME_ARCHIVE})" in
	"${GAME_ARCHIVE1}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE1_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE1_FULLSIZE}"
		PKG2_NAME="${PKG2_ID}-en_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}"
	;;
	"${GAME_ARCHIVE2}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE2_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE2_FULLSIZE}"
		PKG2_NAME="${PKG2_ID}-fr_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}"
	;;
esac
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_NAME}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG3_DIR' "${PKG3_ID}_${PKG3_VERSION}-${PKG_REVISION}_${PKG3_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG4_DIR' "${PKG4_ID}_${PKG4_VERSION}-${PKG_REVISION}_${PKG4_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG5_DIR' "${PKG5_ID}_${PKG5_VERSION}-${PKG_REVISION}_${PKG5_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG6_DIR' "${PKG6_ID}_${PKG6_VERSION}-${PKG_REVISION}_${PKG6_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE_MD5}"
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}"
rm -Rf "${PKG2_DIR}" "${PKG3_DIR}" "${PKG4_DIR}" "${PKG5_DIR}" "${PKG6_DIR}"
mkdir -p "${PKG2_DIR}/DEBIAN" "${PKG2_DIR}${PATH_GAME}"
mkdir -p "${PKG3_DIR}/DEBIAN" "${PKG3_DIR}${PATH_GAME}"
mkdir -p "${PKG4_DIR}/DEBIAN" "${PKG4_DIR}${PATH_GAME}"
mkdir -p "${PKG5_DIR}/DEBIAN" "${PKG5_DIR}${PATH_GAME}"
mkdir -p "${PKG6_DIR}/DEBIAN" "${PKG6_DIR}${PATH_GAME}" "${PKG6_DIR}${PATH_ICON_BASE}"
print wait

extract_data 'unar_passwd' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet,tolower'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_JUNK}; do
	rm -Rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	if [ -e "${file}" ]; then
		mkdir -p "${PKG2_DIR}${PATH_GAME}/${file%/*}"
		mv "${file}" "${PKG2_DIR}${PATH_GAME}/${file}"
	fi
done

for file in ${INSTALLER_GAME_PKG3}; do
	mv "${file}" "${PKG3_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG4}; do
	mv "${file}" "${PKG4_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG5}; do
	mv "${file}" "${PKG5_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG6}; do
	mv "${file}" "${PKG6_DIR}${PATH_GAME}"
done
cd - > /dev/null

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
	extract_icons "${APP2_ID}" "${APP2_ICON}" "${APP2_ICON_RES}" "${PKG_TMPDIR}"
	mv "${PKG1_DIR}${PATH_ICON_BASE}"/* "${PKG6_DIR}${PATH_ICON_BASE}"
	rmdir --parents --ignore-fail-on-non-empty "${PKG1_DIR}${PATH_ICON_BASE}"
fi

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"

write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '' "${APP2_NAME}"

write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" "${APP2_CAT}" 'wine'
printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"
write_pkg_debian "${PKG3_DIR}" "${PKG3_ID}" "${PKG3_VERSION}-${PKG_REVISION}" "${PKG3_ARCH}" "${PKG3_CONFLICTS}" "${PKG3_DEPS}" "${PKG3_RECS}" "${PKG3_DESC}"
write_pkg_debian "${PKG4_DIR}" "${PKG4_ID}" "${PKG4_VERSION}-${PKG_REVISION}" "${PKG4_ARCH}" "${PKG4_CONFLICTS}" "${PKG4_DEPS}" "${PKG4_RECS}" "${PKG4_DESC}"
write_pkg_debian "${PKG5_DIR}" "${PKG5_ID}" "${PKG5_VERSION}-${PKG_REVISION}" "${PKG5_ARCH}" "${PKG5_CONFLICTS}" "${PKG5_DEPS}" "${PKG5_RECS}" "${PKG5_DESC}"
write_pkg_debian "${PKG6_DIR}" "${PKG6_ID}" "${PKG6_VERSION}-${PKG_REVISION}" "${PKG6_ARCH}" "${PKG6_CONFLICTS}" "${PKG6_DEPS}" "${PKG6_RECS}" "${PKG6_DESC}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG3_DIR}" "${PKG3_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG4_DIR}" "${PKG4_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG5_DIR}" "${PKG5_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG6_DIR}" "${PKG6_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG1_DESC}" "${PKG6_DIR}" "${PKG5_DIR}" "${PKG4_DIR}" "${PKG3_DIR}" "${PKG2_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"
exit 0
