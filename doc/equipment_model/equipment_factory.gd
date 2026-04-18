## 4. 设备工厂 (创建设备实例)
# 文件: scripts/equipment/equipment_factory.gd

class_name EquipmentFactory
extends RefCounted

## 创建设备实例
static func create_equipment(config: Dictionary) -> BaseEquipment:
    var eq_type = config.get("type", "GENERIC")
    
    match eq_type:
        "LITHO", "LITHOGRAPHY":
            if config.get("gem_mode", false):
                return GEMLITHOEquipment.new(config)
            return LITHOEquipment.new(config)
            
        "CLEAN", "WET":
            if config.get("gem_mode", false):
                # 可以创建 GEMCLEANEquipment
                return CLEANEquipment.new(config)
            return CLEANEquipment.new(config)
            
        "FURNACE", "DIFF", "DIFFUSION":
            if config.get("gem_mode", false):
                return GEMFURNACEEquipment.new(config)
            return FURNACEEquipment.new(config)
            
        "ETCH":
            if config.get("gem_mode", false):
                return GEMETCHEquipment.new(config)
            return ETCHEquipment.new(config)
            
        "METROLOGY", "MEASURE", "INSPECT":
            if config.get("gem_mode", false):
                return GEMMETROLOGYEquipment.new(config)
            return METROLOGYEquipment.new(config)
            
        "GEM":  # 通用 GEM 设备
            return GEMEquipment.new(config)
            
        _:
            # 通用基础设备
            return BaseEquipment.new(config)

## 批量创建设备
static func create_equipment_batch(configs: Array) -> Array:
    var equipments = []
    for config in configs:
        equipments.append(create_equipment(config))
    return equipments

## 创建设备配置模板
static func get_equipment_template(eq_type: String) -> Dictionary:
    match eq_type:
        "LITHO":
            return {
                "type": "LITHO",
                "capacity": 1,
                "process_time": 600,
                "mtbf": 3600,
                "mttr": 900,
                "recipes": ["R_LITHO_01", "R_LITHO_02"],
                "fault_profile": "litho"
            }
            
        "CLEAN":
            return {
                "type": "CLEAN",
                "capacity": 1,
                "process_time": 300,
                "mtbf": 7200,
                "mttr": 600,
                "recipes": ["R_CLEAN_01", "R_CLEAN_02"],
                "fault_profile": "clean"
            }
            
        "FURNACE":
            return {
                "type": "FURNACE",
                "capacity": 100,
                "process_time": 1800,
                "mtbf": 7200,
                "mttr": 1800,
                "recipes": ["R_DIFF_01", "R_DIFF_02"],
                "fault_profile": "furnace"
            }
            
        _:
            return {
                "type": "GENERIC",
                "capacity": 1,
                "process_time": 600,
                "mtbf": 3600,
                "mttr": 900
            }
