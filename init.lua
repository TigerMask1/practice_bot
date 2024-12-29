-- Include the player_api for animations
dofile(minetest.get_modpath("player_api") .. "/api.lua")

minetest.register_entity("practice_bot:bot", {
    hp_max = 40,
    physical = true,
    collisionbox = {-0.3, 0, -0.3, 0.3, 1.7, 0.3},
    visual = "mesh",
    mesh = "character.b3d",
    textures = {"character.png"},
    animations = {
        stand     = {x = 0,   y = 79},
        walk      = {x = 168, y = 187},
        attack    = {x = 189, y = 198},
    },
    animation_speed = 30,
    current_animation = "stand",
    attack_range = 20,
    attack_damage = 2,
    cooldown = 0.1,
    last_attack_time = 0,
    speed = 4,
    bot_type = "easy",
    set_animation = function(self, animation)
        if self.current_animation ~= animation then
            local anim = self.animations[animation]
            if anim then
                self.object:set_animation(anim, self.animation_speed, 0)
                self.current_animation = animation
            end
        end
    end,

    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        local velocity = self.object:get_velocity()
        local players = minetest.get_connected_players()
        local nearest_player = nil
        local nearest_distance = self.attack_range

        for _, player in ipairs(players) do
            local player_pos = player:get_pos()
            local distance = vector.distance(pos, player_pos)

            if distance <= self.attack_range and distance < nearest_distance then
                nearest_player = player
                nearest_distance = distance
            end
        end

        if not self.is_on_ground then
            velocity.y = velocity.y - 9.8 * dtime
        end

        if nearest_player then
            local player_pos = nearest_player:get_pos()
            local distance = vector.distance(pos, player_pos)

            local dir = vector.subtract(player_pos, pos)
            dir.y = 0
            local yaw = math.atan2(dir.z, dir.x) - math.pi / 2
            self.object:set_yaw(yaw)

            if distance > 1 then
                self:set_animation("walk")

                local new_velocity = vector.multiply(vector.normalize(dir), self.speed)
                new_velocity.y = velocity.y
                self.object:set_velocity(new_velocity)
            else
                local current_time = minetest.get_gametime()
                if current_time - self.last_attack_time >= self.cooldown then
                    self:set_animation("attack")
                    nearest_player:punch(self.object, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = self.attack_damage}})
                    self.last_attack_time = current_time
                end

                self.object:set_velocity({x = 0, y = velocity.y, z = 0})
            end
        else
            self:set_animation("stand")
            self.object:set_velocity({x = 0, y = velocity.y, z = 0})
        end

        local node_below = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
        self.is_on_ground = node_below and minetest.registered_nodes[node_below.name] and minetest.registered_nodes[node_below.name].walkable

        if self.is_on_ground and velocity.y == 0 then
            local step_pos = vector.add(pos, vector.multiply(vector.normalize({x = velocity.x, y = 0, z = velocity.z}), 0.5))
            step_pos.y = step_pos.y + 0.5
            local step_node = minetest.get_node_or_nil(step_pos)

            if step_node and minetest.registered_nodes[step_node.name] and minetest.registered_nodes[step_node.name].walkable then
                self.object:set_velocity({x = velocity.x, y = 6, z = velocity.z})
            end
        end
    end

})

local function spawn_practice_bot(pos, config)
    local bot_pos = vector.add(pos, {x = 0, y = 1, z = 0})
    local bot = minetest.add_entity(bot_pos, "practice_bot:bot")
    if bot then
        local bot_lua = bot:get_luaentity()
        if bot_lua then
            bot_lua.hp_max = config.hp_max
            bot_lua.object:set_hp(config.hp_max)
            bot_lua.speed = config.speed
            bot_lua.attack_damage = config.attack_damage
            bot_lua.cooldown = config.cooldown
        end
    end
end

minetest.register_tool("practice_bot:spawner_breaker", {
    description = "Spawner Breaker Axe",
    inventory_image = "spawner_breaker.png",
    tool_capabilities = {
        full_punch_interval = 0.5,
        max_drop_level = 1,
        groupcaps = {
            spawner_breakable = {times = {[1] = 1.0, [2] = 0.5, [3] = 0.2}, uses = 30, maxlevel = 3},
        },
        damage_groups = {fleshy = 5},
    },
})

minetest.register_node("practice_bot:easy_spawner", {
    description = "Easy Bot Spawner",
    tiles = {"spawner_top.png", "easy_spawner_side.png"},
    groups = {spawner_breakable = 1},
    on_rightclick = function(pos)
        spawn_practice_bot(pos, {
            hp_max = 10,
            speed = 2,
            attack_damage = 1,
            cooldown = 1.0
        })
    end
})

minetest.register_node("practice_bot:medium_spawner", {
    description = "Medium Bot Spawner",
    tiles = {"spawner_top.png", "medium_spawner_side.png"},
    groups = {spawner_breakable = 1},
    on_rightclick = function(pos)
        spawn_practice_bot(pos, {
            hp_max = 20,
            speed = 3,
            attack_damage = 2,
            cooldown = 0.5
        })
    end
})

minetest.register_node("practice_bot:difficult_spawner", {
    description = "Difficult Bot Spawner",
    tiles = {"spawner_top.png", "hard_spawner_side.png"},
    groups = {spawner_breakable = 1},
    on_rightclick = function(pos)
        spawn_practice_bot(pos, {
            hp_max = 30,
            speed = 5,
            attack_damage = 4,
            cooldown = 0.3
        })
    end
})

minetest.register_craftitem("practice_bot:easy_spawner_item", {
    description = "Easy Bot Spawner Item",
    inventory_image = "easy_spawner_side.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.under then
            spawn_practice_bot(pointed_thing.under, {
                hp_max = 10,
                speed = 2,
                attack_damage = 1,
                cooldown = 1.0
            })
            itemstack:take_item()
        end
        return itemstack
    end
})

minetest.register_craftitem("practice_bot:medium_spawner_item", {
    description = "Medium Bot Spawner Item",
    inventory_image = "medium_spawner_side.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.under then
            spawn_practice_bot(pointed_thing.under, {
                hp_max = 20,
                speed = 3,
                attack_damage = 2,
                cooldown = 0.5
            })
            itemstack:take_item()
        end
        return itemstack
    end
})

minetest.register_craftitem("practice_bot:difficult_spawner_item", {
    description = "Difficult Bot Spawner Item",
    inventory_image = "hard_spawner_side.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.under then
            spawn_practice_bot(pointed_thing.under, {
                hp_max = 30,
                speed = 5,
                attack_damage = 4,
                cooldown = 0.3
            })
            itemstack:take_item()
        end
        return itemstack
    end
})
