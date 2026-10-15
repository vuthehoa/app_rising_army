/// Danh sách mọi painter trang bị theo thư mục. Thêm thiết kế mới = thêm tệp painter + một dòng ở đây;
/// test `equipment_painters_test` đảm bảo danh sách này khớp từng id của `EquipmentCatalog`.
library;

import '../equipment_painter.dart';
import 'armor/abyss_plate.dart';
import 'armor/banded_mail.dart';
import 'armor/bark_vest.dart';
import 'armor/blackened_plate.dart';
import 'armor/brigandine_coat.dart';
import 'armor/brigandine_vest.dart';
import 'armor/bronze_cuirass.dart';
import 'armor/buff_coat.dart';
import 'armor/chain_mail.dart';
import 'armor/coat_of_plates.dart';
import 'armor/cuirassier_plate.dart';
import 'armor/dragon_scale_armor.dart';
import 'armor/drake_hide.dart';
import 'armor/full_plate.dart';
import 'armor/fur_jerkin.dart';
import 'armor/gambeson_tabard.dart';
import 'armor/gothic_plate.dart';
import 'armor/half_plate.dart';
import 'armor/hardened_leather.dart';
import 'armor/hide_vest.dart';
import 'armor/knight_harness.dart';
import 'armor/knight_hauberk.dart';
import 'armor/lamellar_cuirass.dart';
import 'armor/lamellar_light.dart';
import 'armor/leather_armor.dart';
import 'armor/linen_tunic.dart';
import 'armor/lion_heart_armor.dart';
import 'armor/mail_and_plate.dart';
import 'armor/mantle_mail.dart';
import 'armor/moon_lamellar.dart';
import 'armor/ornate_lamellar.dart';
import 'armor/padded_armor.dart';
import 'armor/paladin_surcoat.dart';
import 'armor/phoenix_mail.dart';
import 'armor/plate_armor.dart';
import 'armor/reed_armor.dart';
import 'armor/ring_mail.dart';
import 'armor/rope_vest.dart';
import 'armor/royal_plate.dart';
import 'armor/runed_mail.dart';
import 'armor/scale_jerkin.dart';
import 'armor/scale_mail.dart';
import 'armor/smith_apron.dart';
import 'armor/splint_mail.dart';
import 'armor/steel_cuirass.dart';
import 'armor/storm_cuirass.dart';
import 'armor/studded_leather.dart';
import 'armor/sun_aegis.dart';
import 'armor/titan_harness.dart';
import 'armor/warlord_brigandine.dart';
import 'shields/door_shield.dart';
import 'shields/dragon_shield.dart';
import 'shields/heater_shield.dart';
import 'shields/hex_shield.dart';
import 'shields/kite_shield.dart';
import 'shields/knight_shield.dart';
import 'shields/lion_shield.dart';
import 'shields/lozenge_shield.dart';
import 'shields/ogee_shield.dart';
import 'shields/pavise_shield.dart';
import 'shields/round_shield.dart';
import 'shields/scutum_shield.dart';
import 'shields/spiked_buckler.dart';
import 'shields/sun_shield.dart';
import 'shields/targe_shield.dart';
import 'shields/tower_shield.dart';
import 'shields/wicker_shield.dart';
import 'shields/winged_shield.dart';
import 'shields/wood_buckler.dart';
import 'shields/wooden_shield.dart';
import 'weapons/arming_sword.dart';
import 'weapons/assassin_dirk.dart';
import 'weapons/bastard_sword.dart';
import 'weapons/battle_axe.dart';
import 'weapons/battle_saber.dart';
import 'weapons/bearded_axe.dart';
import 'weapons/berserker_axe.dart';
import 'weapons/billhook_pole.dart';
import 'weapons/boar_spear.dart';
import 'weapons/bone_knife.dart';
import 'weapons/broad_sword.dart';
import 'weapons/composite_bow.dart';
import 'weapons/crescent_greataxe.dart';
import 'weapons/crescent_saber.dart';
import 'weapons/curved_machete.dart';
import 'weapons/dagger.dart';
import 'weapons/dane_axe.dart';
import 'weapons/double_bit_axe.dart';
import 'weapons/dragon_bow.dart';
import 'weapons/dragon_fang_spear.dart';
import 'weapons/dragon_saber.dart';
import 'weapons/estoc_sword.dart';
import 'weapons/executioner_sword.dart';
import 'weapons/falchion.dart';
import 'weapons/flamberge.dart';
import 'weapons/flanged_mace.dart';
import 'weapons/frostbrand.dart';
import 'weapons/gilded_spear.dart';
import 'weapons/great_axe.dart';
import 'weapons/halberd.dart';
import 'weapons/hand_cleaver.dart';
import 'weapons/harpoon_spear.dart';
import 'weapons/heavy_crossbow.dart';
import 'weapons/horn_bow.dart';
import 'weapons/hunting_bow.dart';
import 'weapons/iron_dirk.dart';
import 'weapons/iron_flail.dart';
import 'weapons/iron_gladius.dart';
import 'weapons/iron_glaive.dart';
import 'weapons/iron_spear.dart';
import 'weapons/iron_zweihander.dart';
import 'weapons/javelin.dart';
import 'weapons/knight_poleaxe.dart';
import 'weapons/knight_sword.dart';
import 'weapons/knight_warhammer.dart';
import 'weapons/kris_dagger.dart';
import 'weapons/light_crossbow.dart';
import 'weapons/lightning_javelin.dart';
import 'weapons/logging_axe.dart';
import 'weapons/long_bow.dart';
import 'weapons/lucerne_hammer.dart';
import 'weapons/mason_maul.dart';
import 'weapons/moonlight_saber.dart';
import 'weapons/morning_star.dart';
import 'weapons/noble_rapier.dart';
import 'weapons/parrying_dagger.dart';
import 'weapons/partisan_spear.dart';
import 'weapons/peasant_crossbow.dart';
import 'weapons/phoenix_glaive.dart';
import 'weapons/pitchfork.dart';
import 'weapons/recurve_bow.dart';
import 'weapons/riders_lance.dart';
import 'weapons/rondel_dagger.dart';
import 'weapons/royal_halberd.dart';
import 'weapons/royal_sword.dart';
import 'weapons/rusted_blade.dart';
import 'weapons/rusty_claymore.dart';
import 'weapons/scimitar.dart';
import 'weapons/serrated_dirk.dart';
import 'weapons/shamshir.dart';
import 'weapons/short_bow.dart';
import 'weapons/short_sword.dart';
import 'weapons/siege_crossbow.dart';
import 'weapons/silverwood_bow.dart';
import 'weapons/sky_bow.dart';
import 'weapons/spiked_club.dart';
import 'weapons/spiked_flail.dart';
import 'weapons/steel_crossbow.dart';
import 'weapons/steel_cutlass.dart';
import 'weapons/steel_longsword.dart';
import 'weapons/steel_pike.dart';
import 'weapons/steel_spear.dart';
import 'weapons/stiletto.dart';
import 'weapons/stone_hammer.dart';
import 'weapons/storm_flail.dart';
import 'weapons/sun_blade.dart';
import 'weapons/sunfire_mace.dart';
import 'weapons/thresher_flail.dart';
import 'weapons/thunder_axe.dart';
import 'weapons/titan_greatsword.dart';
import 'weapons/trident.dart';
import 'weapons/triple_flail.dart';
import 'weapons/twin_fang_sword.dart';
import 'weapons/venom_fang.dart';
import 'weapons/war_bow.dart';
import 'weapons/war_hammer.dart';
import 'weapons/woodcutter_axe.dart';
import 'weapons/wooden_club.dart';
import 'weapons/wooden_spear.dart';
import 'weapons/xiphos_sword.dart';

/// Áo giáp: 50 painter.
const List<EquipmentPainter> armorPainters = [
  AbyssPlatePainter(),
  BandedMailPainter(),
  BarkVestPainter(),
  BlackenedPlatePainter(),
  BrigandineCoatPainter(),
  BrigandineVestPainter(),
  BronzeCuirassPainter(),
  BuffCoatPainter(),
  ChainMailPainter(),
  CoatOfPlatesPainter(),
  CuirassierPlatePainter(),
  DragonScaleArmorPainter(),
  DrakeHidePainter(),
  FullPlatePainter(),
  FurJerkinPainter(),
  GambesonTabardPainter(),
  GothicPlatePainter(),
  HalfPlatePainter(),
  HardenedLeatherPainter(),
  HideVestPainter(),
  KnightHarnessPainter(),
  KnightHauberkPainter(),
  LamellarCuirassPainter(),
  LamellarLightPainter(),
  LeatherArmorPainter(),
  LinenTunicPainter(),
  LionHeartArmorPainter(),
  MailAndPlatePainter(),
  MantleMailPainter(),
  MoonLamellarPainter(),
  OrnateLamellarPainter(),
  PaddedArmorPainter(),
  PaladinSurcoatPainter(),
  PhoenixMailPainter(),
  PlateArmorPainter(),
  ReedArmorPainter(),
  RingMailPainter(),
  RopeVestPainter(),
  RoyalPlatePainter(),
  RunedMailPainter(),
  ScaleJerkinPainter(),
  ScaleMailPainter(),
  SmithApronPainter(),
  SplintMailPainter(),
  SteelCuirassPainter(),
  StormCuirassPainter(),
  StuddedLeatherPainter(),
  SunAegisPainter(),
  TitanHarnessPainter(),
  WarlordBrigandinePainter(),
];

/// Vũ khí: 100 painter.
const List<EquipmentPainter> weaponPainters = [
  ArmingSwordPainter(),
  AssassinDirkPainter(),
  BastardSwordPainter(),
  BattleAxePainter(),
  BattleSaberPainter(),
  BeardedAxePainter(),
  BerserkerAxePainter(),
  BillhookPolePainter(),
  BoarSpearPainter(),
  BoneKnifePainter(),
  BroadSwordPainter(),
  CompositeBowPainter(),
  CrescentGreataxePainter(),
  CrescentSaberPainter(),
  CurvedMachetePainter(),
  DaggerPainter(),
  DaneAxePainter(),
  DoubleBitAxePainter(),
  DragonBowPainter(),
  DragonFangSpearPainter(),
  DragonSaberPainter(),
  EstocSwordPainter(),
  ExecutionerSwordPainter(),
  FalchionPainter(),
  FlambergePainter(),
  FlangedMacePainter(),
  FrostbrandPainter(),
  GildedSpearPainter(),
  GreatAxePainter(),
  HalberdPainter(),
  HandCleaverPainter(),
  HarpoonSpearPainter(),
  HeavyCrossbowPainter(),
  HornBowPainter(),
  HuntingBowPainter(),
  IronDirkPainter(),
  IronFlailPainter(),
  IronGladiusPainter(),
  IronGlaivePainter(),
  IronSpearPainter(),
  IronZweihanderPainter(),
  JavelinPainter(),
  KnightPoleaxePainter(),
  KnightSwordPainter(),
  KnightWarhammerPainter(),
  KrisDaggerPainter(),
  LightCrossbowPainter(),
  LightningJavelinPainter(),
  LoggingAxePainter(),
  LongBowPainter(),
  LucerneHammerPainter(),
  MasonMaulPainter(),
  MoonlightSaberPainter(),
  MorningStarPainter(),
  NobleRapierPainter(),
  ParryingDaggerPainter(),
  PartisanSpearPainter(),
  PeasantCrossbowPainter(),
  PhoenixGlaivePainter(),
  PitchforkPainter(),
  RecurveBowPainter(),
  RidersLancePainter(),
  RondelDaggerPainter(),
  RoyalHalberdPainter(),
  RoyalSwordPainter(),
  RustedBladePainter(),
  RustyClaymorePainter(),
  ScimitarPainter(),
  SerratedDirkPainter(),
  ShamshirPainter(),
  ShortBowPainter(),
  ShortSwordPainter(),
  SiegeCrossbowPainter(),
  SilverwoodBowPainter(),
  SkyBowPainter(),
  SpikedClubPainter(),
  SpikedFlailPainter(),
  SteelCrossbowPainter(),
  SteelCutlassPainter(),
  SteelLongswordPainter(),
  SteelPikePainter(),
  SteelSpearPainter(),
  StilettoPainter(),
  StoneHammerPainter(),
  StormFlailPainter(),
  SunBladePainter(),
  SunfireMacePainter(),
  ThresherFlailPainter(),
  ThunderAxePainter(),
  TitanGreatswordPainter(),
  TridentPainter(),
  TripleFlailPainter(),
  TwinFangSwordPainter(),
  VenomFangPainter(),
  WarBowPainter(),
  WarHammerPainter(),
  WoodcutterAxePainter(),
  WoodenClubPainter(),
  WoodenSpearPainter(),
  XiphosSwordPainter(),
];

/// Khiên: 20 painter.
const List<EquipmentPainter> shieldPainters = [
  DoorShieldPainter(),
  DragonShieldPainter(),
  HeaterShieldPainter(),
  HexShieldPainter(),
  KiteShieldPainter(),
  KnightShieldPainter(),
  LionShieldPainter(),
  LozengeShieldPainter(),
  OgeeShieldPainter(),
  PaviseShieldPainter(),
  RoundShieldPainter(),
  ScutumShieldPainter(),
  SpikedBucklerPainter(),
  SunShieldPainter(),
  TargeShieldPainter(),
  TowerShieldPainter(),
  WickerShieldPainter(),
  WingedShieldPainter(),
  WoodBucklerPainter(),
  WoodenShieldPainter(),
];
