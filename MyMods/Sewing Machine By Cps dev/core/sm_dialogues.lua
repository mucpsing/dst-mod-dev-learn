Dialogues = {}

-- 角色拒绝台词
Dialogues.REJECT_LINES = {
	willow = "把这个当线材用？还不如让我烧了！",
	wolfgang = "沃尔夫冈认为这个不能作为线轴来用。",
	wendy = "那只能让衣物比我的心更加千疮百孔。",
	wx78 = "错误，补丁不兼容。",
	wickerbottom = "亲爱的，我从来没见过用这个缝衣服的。",
	woodie = "不行，这个甚至都不能修我的格子衫。",
	waxwell = "我的西服怎么能容许被这种材料羞辱？",
	wathgrithr = "这个材料无法为勇士们缝补战衣。",
	webber = "我们觉得用这个修衣服会出大问题的。",
	winona = "不行，添加用料这种事，一定要严之又严。",
	warly = "啊，你会用番茄条蘸土豆酱吗？",
	wortox = "哼，如果这是一场恶作剧，那么我可能会把这东西扔进去。",
	wormwood = "嗖嗖不喜欢这个",
	wurt = "浮浪噗，我很清醒，不会乱塞东西的。",
	walter = "沃比的毛都比这东西适合缝纫。",
	wanda = "我没时间在这里给材料试错，拿对的来！",
	wirlywings = "唔姆，这个肯定不行，我还是有点缝纫知识的！",
	daidai = "嗯，这个是绝对修不了玩偶和衣服的",
	wathom = "材料，不正确。",
	winky = "……我觉得还没有我们的体毛合适。",
	wixie = "有这试材料的时间不如去打弹弓。",
	default = "用这个来缝纫是不科学的。",
}


-- 获取角色台词
Dialogues.getRejectMsg = function(character)
	return Dialogues.REJECT_LINES[character] or Dialogues.REJECT_LINES.default
end
