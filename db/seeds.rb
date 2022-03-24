
User.all.destroy_all
u0 = User.create! firstname: 'Peter', lastname: 'Williams', shortname: 'BertieR', email: 'prw20042004@yahoo.co.uk', password: '123456', description: "Coder by day, existential worrier by night.The day job and my years back in the day as an astrophysicist have shown me how amazing our progress as a species is. And how fragile our civilization is. Risk of near species extinction has never been higher- we're evolving fast, ever faster, and without a safety harness. At 1-Squared we're going to make a record of everything worth keeping from our incredible civilization. Just in case...", role: User.roles[:admin]
u1 = User.create! firstname: 'Luther', lastname: 'Jones', shortname: 'Luther', email: 'lutherjones@me.com', description: "We should probably not forget to write down how we did this stuff, we're bound to forget.", password: '123456', role: User.roles[:admin]

u2 = User.create! firstname: 'Arthur', lastname: 'Jones', shortname: 'Arthur', email: 'ajonesfilm@gmail.com', description: 'Keen observer', password: '123456'
u3 = User.create! firstname: 'Bob', lastname: 'Niro', shortname: 'bobniro', email: 'bob2425@yahoo.com', description: '', password: '123456'
u4 = User.create! firstname: 'Diane', lastname: 'Worthington', shortname: 'DianeW', email: 'elenways@gmail.com', description: 'Crafting, creating, dreaming and living simply on our narrowboat home on a canal in South Yorkshire.', password: '123456'
u5 = User.create! firstname: 'Frida', lastname: 'Jones', shortname: 'Frida Jones', email: 'Fridadjones@icloud.com', description: '', password: '123456'
u6 = User.create! firstname: 'Jude', lastname: 'Jones', shortname: 'Jude1', email: 'judith@saxonhouse.co.uk', description: "Ex English and Drama teacher. Gardener and vegetable grower. Baker and preserver. Custodian and demonstrator of Saxonhouse. Writer and proof reader.", password: '123456'
u7 = User.create! firstname: 'Mike', lastname: 'Read', shortname: 'mread', email: 'mikeread@radio2.com', description: '', password: '123456'
u8 = User.create! firstname: 'Spankhorn', lastname: 'Muzzge', shortname: 'Spanghorn Muzzke', email: 'bkgmon@hotmail.com', description: '', password: '123456'
u9 = User.create! firstname: 'Steve', lastname: 'Jones', shortname: 'Steve1', email: 'stevebiljones@gmail.com', description: "I've lived with my family just north of Lincoln for the past 32 years and have taught art in secondary schools since 1975.<br />It's no coincidence that I chose splitting wood and carving same for my first 1squared.org project as we have built a reconstruction of a 7th. Century house on our land.", password: '123456'
u10 = User.create! firstname: 'Vivi', lastname: 'Tai', shortname: 'Vivi', email: 'taixian811@gmail.com', description: '', password: '123456'
u11 = User.create! firstname: 'Mark', lastname: 'Pallis', shortname: 'Mark', email: 'mark@pallis', description: '', password: '123456'

Category.all.destroy_all
c5 = Category.create! name: 'Self', description: 'Philosophy, spirituality & enlightenment', level: 5
c4 = Category.create! name: 'Culture', description: 'Accomplishment, creativity & mastery', level: 4
c3 = Category.create! name: 'Tribe', description: 'Friendship, intimacy & social order', level: 3
c2 = Category.create! name: 'Home', description: 'Shelter, safety & security', level: 2
c1 = Category.create! name: 'Body', description: 'Water, sustenance & other basic needs', level: 1

Article.all.destroy_all
Step.all.destroy_all
Ingredient.all.destroy_all

#a10 = Article.create! title: "", author: u1, description: "", category: c4, status: Article.statuses[:published]
#i100 = Ingredient.create! description: "", article: a10, order: 1
#s100 = Step.create! title: "", instruction: "", article: a10, order: 1

a13 = Article.create! title: "Putting pajamas on a child", author: u11, description: "At the end of a long day, no one wants to spend ages getting the children into their PJs.  This simple trick will save you time and will make the whole thing fun.", category: c1, status: Article.statuses[:published]
i130 = Ingredient.create! description: "Pajamas", article: a13, order: 1
i131 = Ingredient.create! description: "A child", article: a13, order: 2
i132 = Ingredient.create! description: "A soft toy", article: a13, order: 3
s130 = Step.create! title: "Preparation", instruction: "Get a pair of pajamas and stuff one soft toy down the leg and another soft toy down the arm. It should go in head first, so that the head is the first thing that pops out of the cuff. The toys should be big, and it should look very, very obvious that there is something in the pajamas.", article: a13, order: 1
s131 = Step.create! title: "Play it cool", instruction: "Pretend that it's just any other bedtime. Deny any knowledge that there is anything unusual about the pajamas: 'They're just ordinary pajamas'.", article: a13, order: 2
s132 = Step.create! title: "Put the empty trouser leg and sleeve on first", instruction: "You're half way there!", article: a13, order: 3
s133 = Step.create! title: "Ta Daaa!", instruction: "Now let the child push the teddy out of the sleeve and trouser leg. They will love it and then, as if by magic, they'll have their PJs on.", article: a13, order: 4

a14 = Article.create! title: "How to construct a well-tempered musical scale", author: u0, description: "Western music after the Renaissance is almost exclusively on a well-tempered scale. This is a scale of 12 notes constructed from a circle of 5ths.", category: c4, status: Article.statuses[:published]
i140 = Ingredient.create! description: "some form of string, rope or twine", article: a14, order: 1
i141 = Ingredient.create! description: "lengths of wood on which the string can be stretched over, which differ in size by a factor of 2/3s", article: a14, order: 2
s140 = Step.create! title: "Stretch the string over wood and pull tight, tying the ends", instruction: "This needs to be as large as you can, starting with the lowest note you will need.", article: a14, order: 1
s141 = Step.create! title: "Stretch the next string over a piece of wood two thirds the length of the first", instruction: "This will provide an interval of a fifth above the first string.", article: a14, order: 2
s142 = Step.create! title: "Tune to an octave lower", instruction: "Take a length of wood as long as the first, and tune the note from the wood which is two-thirds the length but an octave lower.", article: a14, order: 3
s143 = Step.create! title: "Repeat the above a number of times", instruction: "By creating a number of these strings tuned a fifth apart, the scale can be covered.", article: a14, order: 4
s144 = Step.create! title: "Intermediate notes on one string", instruction: "Make marks on the wood at a length ratio of 2:3, which gives the full range of notes within the same octave.", article: a14, order: 5

a15 = Article.create! title: "No bread? Try these quick oat biscuits with your cheese", author: u6, description: "Sometimes you can't get hold of bread or panic buying has seen off the ingredients you need to make it. But you need something with your cheese and pickles.", category: c1, status: Article.statuses[:published]
i150 = Ingredient.create! description: "Porridge Oats 225g", article: a15, order: 1
i151 = Ingredient.create! description: "Flour - pref wholemeal 60g", article: a15, order: 2
i152 = Ingredient.create! description: "1/2 tsp bicarb of soda, 1/2 tsp sugar, 1 teasp salt", article: a15, order: 3
i153 = Ingredient.create! description: "70g 'fat' (butter, butter &amp; lard mix or vegan alternative)", article: a15, order: 4
i154 = Ingredient.create! description: "80ml very hot - recently boiled - water", article: a15, order: 5
s150 = Step.create! title: "Oven", instruction: "Preheat to 180C", article: a15, order: 1
s151 = Step.create! title: "Dry ingredients", instruction: "Mix all the dry ingredients together.", article: a15, order: 2
s152 = Step.create! title: "Fat", instruction: "Rub the fat into the flour until it looks a bit like bread crumbs.", article: a15, order: 3
s153 = Step.create! title: "Water", instruction: "Gradually add the water and combine into a thick dough.", article: a15, order: 4
s154 = Step.create! title: "Create the biscuits", instruction: "Lightly flour your work surface, then roll out the dough to approx 1/2 cm thick. Cut into rounds using a biscuit cutter or the bottom of a glass. If you haven't anything round just cut into squares. You could get about a dozen rounds from this amount.", article: a15, order: 5
s155 = Step.create! title: "Bake", instruction: "Put the biscuits onto baking trays and bake until lightly golden brown: 20-30 minutes. Cool on wire racks. Once cold, keep in an airtight tin. Will keep for some time. If they lose their crispness, you can put back in a hot oven for 5+ minutes, cool and replace in the tin.", article: a15, order: 6
s156 = Step.create! title: "Eat with:", instruction: "Cheese, peanut butter, marmite, tuna, cold meat, tomatoes, pickles. Or with honey or jam, banana....", article: a15, order: 7

a16 = Article.create! title: "Holding a referendum", author: u1, description: "Finding the best solution to a problem, and coming to a consensus about a course of actions, is vital to human progress. One way to achieve this is to hold a ballot and allow the majority to decide.", category: c3, status: Article.statuses[:published]
i160 = Ingredient.create! description: "A problem or question", article: a16, order: 1
i161 = Ingredient.create! description: "Some voters", article: a16, order: 2
i162 = Ingredient.create! description: "The same number of pencils and pieces of paper", article: a16, order: 3
i163 = Ingredient.create! description: "A hat", article: a16, order: 4
s160 = Step.create! title: "What is your problem?", instruction: "Ensure that you have condensed the problem into the most simple form.", article: a16, order: 1
s161 = Step.create! title: "What are the solutions?", instruction: "Consider what the possible solutions to the problem are and ensure that everyone agrees on the range of answers.", article: a16, order: 2
s162 = Step.create! title: "Write the question", instruction: "Ensure that the question embodies the problem. Where possible avoid bias or suggestion in the question. Provide 2 or more clear answers which are directly associated to the aforementioned solutions.", article: a16, order: 3
s163 = Step.create! title: "Establish the rules", instruction: "", article: a16, order: 4
s164 = Step.create! title: "Run the vote", instruction: "", article: a16, order: 5

a17 = Article.create! title: "Algorithm for sorting things in order efficiently", author: u0, description: "Many algorithms involve sorting a list of things into order. For large lists, the time this takes can become a blocker. Quicksort is a simple algorithm for sorting large lists which uses a divide-and-conquer approach and just reordering of sub-lists. It scales as n log n where n is the number of elements in the list.", category: c4, status: Article.statuses[:published]
i170 = Ingredient.create! description: "An unsorted list of items you want to sort", article: a17, order: 1
i171 = Ingredient.create! description: "A measure by which they will be sorted", article: a17, order: 2
s170 = Step.create! title: "Pick a random element in the list", instruction: "", article: a17, order: 1
s171 = Step.create! title: "Move all elements less than or equal to the element you choose to the left of this element", instruction: "This will leave all of the elements larger than the element you choose to the right of the element.", article: a17, order: 2
s172 = Step.create! title: "Break the list into two sub-lists, at the randomly selected element", instruction: "Break the list into two sub-lists, at the randomly selected element, but not including that element you selected.", article: a17, order: 3
s173 = Step.create! title: "Goto step 1 and repeat for each of the two sub-lists", instruction: "The divide and conquer approach should be applied recursively to each sub-list, until you are left with lists of size 1 or 2. At that point you will have sorted the full list.", article: a17, order: 4

a18 = Article.create! title: "Drawing a picture", author: u1, description: "Some of the earliest and longest-lasting forms of human communication are the paintings found in caves. Not only do they form a valuable document of animals and hunting practices but they give a window into how people saw the world, their values and their priorities. Perhaps the pictures you make will outlast this book.", category: c4, status: Article.statuses[:published]
i180 = Ingredient.create! description: "Some form of pigment", article: a18, order: 1
i181 = Ingredient.create! description: "A tool to paint or draw with (your hand, a stick, a brush)", article: a18, order: 2
s180 = Step.create! title: "Really look", instruction: "Really look, and try to forget everything you have learnt about what you are looking at. Look sideways, look upside down, squint. Do whatever you can to see what you are seeing for the first time.", article: a18, order: 1
s181 = Step.create! title: "Prepare your pigment", instruction: "Pigment can be sourced from a variety of places: use your blood; burn some wood, grind the charcoal into a powder and then make into a paste with a little water.", article: a18, order: 2
s182 = Step.create! title: "What is your canvas?", instruction: "A wall, a piece of paper, an actual canvas... whatever you like", article: a18, order: 3
s183 = Step.create! title: "Try & repeat", instruction: "Just start. Be unafraid. Make marks, scrape, scratch, daub... you will make ugly marks to start off with but slowly you will learn the craft of getting the most out of the materials you have selected", article: a18, order: 4

a19 = Article.create! title: "The perfect cuppa", author: u1, description: "Making a perfect cup of tea should be considered the default first step in every method.", category: c1, status: Article.statuses[:published]
i190 = Ingredient.create! description: "A kettle", article: a19, order: 1
i191 = Ingredient.create! description: "300ml filtered soft water", article: a19, order: 2
i192 = Ingredient.create! description: "30g tea (ideally loose leaf)", article: a19, order: 3
i193 = Ingredient.create! description: "A small teapot", article: a19, order: 4
i194 = Ingredient.create! description: "A mug (preferably porcelain)", article: a19, order: 5
i195 = Ingredient.create! description: "A tea strainer", article: a19, order: 6
i196 = Ingredient.create! description: "30ml milk (semi skimmed)", article: a19, order: 7
s190 = Step.create! title: "Boil water", instruction: "Many people - most of them in the US - mistakenly believe that you can make tea with hot water. You cannot. The water must be heated to a rolling boil!", article: a19, order: 1
s190 = Step.create! title: "Brew the tea", instruction: "Put the tea leaves (or bag) into the teapot and add the boiling water. Leave it to steep for between 4 and 7 minutes.", article: a19, order: 2
s190 = Step.create! title: "Get ready...", instruction: "Pour the milk into the mug. Always milk first! Place the tea strainer over the mug.", article: a19, order: 3
s190 = Step.create! title: "Serve & enjoy", instruction: "Pour the tea through the strainer. It should be the colour of an envelope. Now take a few moments to just hold the tea and prepare yourself for the first sip... you are almost there.", article: a19, order: 4

a20 = Article.create! title: "Find fresh water when near a beach by digging a well", author: u0, description: "Find fresh water when near a beach by digging a well.", category: c1, status: Article.statuses[:published]
i200 = Ingredient.create! description: "rocks", article: a20, order: 1
s200 = Step.create! title: "Find a location roughly 30 metres from the sea line at high tide, near to sand dunes", instruction: "", article: a20, order: 1
s201 = Step.create! title: "Dig a 10cm wide hole until water seeps into the bottom", instruction: "This water will be a mixture of sand-filtered sea water and rain drainage from the sand dunes. If the water is salty to taste, move further back from the sea line.", article: a20, order: 2
s202 = Step.create! title: "Line the sides and bottom of the well with rocks", instruction: "", article: a20, order: 3
s203 = Step.create! title: "Wait until the well is filled", instruction: "", article: a20, order: 4

a9 = Article.create! title: "How to knit a blanket", author: u4, description: "Keeping warm is one of the most basic of our needs, and as a species we have come up with many ways to do this. One way is quite simply to wrap something around ourselves to keep out the cold .... enter, the blanket. The easiest shape to learn is the square, these can then be stitched together to form a design.", category: c1, status: Article.statuses[:published]
i90 = Ingredient.create! description: "A pair of knitting needles", article: a9, order: 1
i91 = Ingredient.create! description: "Some type of yarn (wool, cotton, acrylic yarn, other plant derived fibre", article: a9, order: 2
i92 = Ingredient.create! description: "Darning needle (for sewing squares together)", article: a9, order: 3
s90 = Step.create! title: "Casting on first stitch", instruction: "How to cast on your first square. Make a slip knot in the end of the yarn. Place the slip knot on the left needle and insert the point of the right needle into it. Wrap the yarn around the right needle tip, then pull this yarn through the slip knot to create another loop (stitch). Move the stitch to left needle. Pull the yarn to secure.", article: a9, order: 1
s91 = Step.create! title: "Cast on continued", instruction: "You will now have two stitches on your left hand needle. Continue in this way until you have required number of stitches to create the size of square you want.", article: a9, order: 2
s92 = Step.create! title: "Knitting the first stitch", instruction: "Insert the tip of the right needle into the first stitch, pushing up and behind the needle in the left hand. This will mean that your needles will end up crossed, the right-hand needle underneath the left hand needle. Wrap the yarn anti-clockwise around the right hand needle. With the right hand needle pull the yarn you have just wrapped around back through the loop. To complete the knit stitch, slip the left-hand stitch off the left needle.", article: a9, order: 3
s93 = Step.create! title: "Work the first square", instruction: "Now knit the other stitches in the same way, to the end of the row. Work sufficient rows to create a square.", article: a9, order: 4
s94 = Step.create! title: "Cast off", instruction: "Knit first 2 stitches loosely. With right hand needle, pull first stitch over 2nd, leaving only 1 on left hand needle. Knit next stitch, and pull the other one over it in the same way. Continue in this way until only 1 stitch remains. Cut yarn, pull the loose end through remaining stitch, slip of needle and pull tight.", article: a9, order: 5
s95 = Step.create! title: "Complete the blanket", instruction: "Make further squares using the same method to create the size 9f blanket required. Using yarn and the darning needle, stitch squares together. There you have it. A lovely warm blanket!", article: a9, order: 6
s96 = Step.create! title: "Further ideas", instruction: "Squares created in this way can also be stitched together to create shawls, and wraps, bags and cushions and even jumpers and jackets!", article: a9, order: 7

a10 = Article.create! title: "Apostrophes are Easy", author: u6, description: "We don’t actually need apostrophes: we can talk without them and still make the meaning clear. And they’ll probably eventually disappear. But if you want to impress on an application letter, it’s as well to use them correctly. And despite the efforts of some teachers to make them seem impenetrable, there is a really easy way to get them right.", category: c4, status: Article.statuses[:published]
i100 = Ingredient.create! description: "Nothing. But paper and a pencil would be useful if you want to practise.", article: a10, order: 1
s100 = Step.create! title: "Decide which bit of the phrase is ‘the owner’.", instruction: "You want to write about the tail that’s on a mouse? Or the cars that belong to the women? Or the crown that sits on the head of the princess? Ok, so the owners are the mouse, the women, the princess. Relax. That’s the hardest bit.", article: a10, order: 1
s101 = Step.create! title: "Now take the name of the owner...", instruction: "and add an apostrophe and an s. We now have: the mouse’s tail; the women’s cars; the princess’s crown", article: a10, order: 2
s102 = Step.create! title: "Take a look at that last one.", instruction: "Yes, s is written three times - but the last one is separated by an apostrophe. DO NOT start to add an e in there!", article: a10, order: 3
s103 = Step.create! title: "Just one more point..", instruction: "..which frankly you’ll rarely use. If you have a plural owner which already ends in s or a double s you just need to add the apostrophe and forget about an extra s. So, if that princess happens to have another couple of sisters, you will write: the princesses’ crowns. (nb There is only an e in princesses because the word is already plural.)", article: a10, order: 4
s104 = Step.create! title: "That’s it.", instruction: "I told you it is easy. Have a practice if you want. Think of people or things that might 'own' something else.  And follow the easy route to perfect apostrophes.", article: a10, order: 5

a11 = Article.create! title: "Spooning", author: u8, description: "Guilt free sleep during soppy films.", category: c3, status: Article.statuses[:published]
i110 = Ingredient.create! description: "A partner", article: a11, order: 1
i111 = Ingredient.create! description: "A sofa", article: a11, order: 2
i112 = Ingredient.create! description: "A soppy film", article: a11, order: 3
s110 = Step.create! title: "Sit on the sofa with your partner", instruction: "Side by side is preferable to begin with.", article: a11, order: 1
s111 = Step.create! title: "Watch soppy film", instruction: "Preferably in the evening, when it is dark, after a few sherries.", article: a11, order: 2
s112 = Step.create! title: "Suggest to your partner that you spoon", instruction: "Though there are other methods, \"Wanna spoon\" is the most commonly accepted form, and first timers are encouraged to use it without either embellishment or shortening.", article: a11, order: 3
s113 = Step.create! title: "Adopt the position", instruction: "Spooning is achieved through that act of one person cuddling another from behind whilst both persons are recumbent. Participants should aim to have their feet on the same of the sofa as each other, with their heads both resting on the arm on the opposite side to their feet. Cushions can be used to supplement this position, if the big spoon* can't see the film. *big spoon is the name given to the person on the outside of this arrangement, with the little spoon being located directly in front of", article: a11, order: 4
s114 = Step.create! title: "Fall asleep", instruction: "It is generally acceptable for either spoon to fall asleep at any point after the spoon has reached peak comfort. NB. If you can wake up just before the film ends, the addition of, \"well that was nice, I'm glad we watched it\" will let you know if your sleeping was observed and may excuse you from second and subsequent viewings.", article: a11, order: 5

a12 = Article.create! title: "Running an errand", author: u8, description: "Old people will need stuff.", category: c3, status: Article.statuses[:published]
i120 = Ingredient.create! description: "A slightly incapacitated or lazy older person or parent", article: a12, order: 1
i121 = Ingredient.create! description: "A vague or particular task", article: a12, order: 2
s120 = Step.create! title: "Are you an orphan?", instruction: "Yes - befriend an kind older person, someone as nice or better than your parents were, or of whom you'd have a reasonable expectation of them being. No - wait.", article: a12, order: 1
s121 = Step.create! title: "Receive errand", instruction: "At some point you will be asked to do something. Listen carefully and check understanding if required.", article: a12, order: 2
s122 = Step.create! title: "Complete errand", instruction: "Do what you've been told and return if appropriate on completion.", article: a12, order: 3

a4 = Article.create! title: 'Make sure your new society has a conception of God', author: u0, description: "All societies, secular or religious, have their God, or Gods. Implicit in doing anything with a specific aim in mind is a value system. By aiming to do it, we've set out that there is more value in achieving the goal than not. Human communities involve numerous activities, each with their own goals and aims. People will vary in their skill level across all goals. Someone will be the best at each one. But what about the ideal person who's best at all of them? That's God.", category: c5, status: Article.statuses[:published]
i40 = Ingredient.create! description: "Clear thinking on what the conception of God looks like for the society you've created.", article: a4, order: 1
i41 = Ingredient.create! description: "Clear thinking on the value systems at play in your society.", article: a4, order: 2
s40 = Step.create! title: "How's it done?", instruction: "God only knows...", article: a4, order: 1

a5 = Article.create! title: "The necessity for story telling", author: u0, description: "Stories are a form of knowledge intermediate between the subjective and objective. Stories contain knowledge which is the fossilized fruit of our evolution: heuristics, patterns of behaviour, morals, which have survived the journey through the oral tradition because of their usefulness. Sometimes this knowledge cannot be easily disembodied from the story into a moral, it's ephemeral and difficult to pin down. And yet we all know a good story and enjoy the retelling.", category: c4, status: Article.statuses[:published]
i50 = Ingredient.create! description: 'A corpus of stories, either written or from memory', article: a5, order: 1
i51 = Ingredient.create! description: 'Young children', article: a5, order: 2
s50 = Step.create! title: 'At every opportunity, tell these stories', instruction: 'Pass them on, get the kids excited.', article: a5, order: 1
s51 = Step.create! title: 'Encourage the children to tell their own stories', instruction: 'Creativity is key.', article: a5, order: 2

a6 = Article.create! title: "Learning and the Goldilocks Zone of Order and Chaos", author: u0, description: "Really bad things happen, they always will: we can never be in full control of our environment or even of ourselves. But by adopting a mental framework in which to ground events both good and bad, we are able to learn and move on.", category: c5, status: Article.statuses[:published]
i60 = Ingredient.create! description: "A self-reflective mind", article: a6, order: 1
s60 = Step.create! title: "Consider bad events to exist in the world of Chaos.", instruction: "These are happenings which do not fit in with our expectations or wants. They are by definition elements of the universe we don't have control over to predict.", article: a6, order: 1
s61 = Step.create! title: "Consider good events to exist in the world of Order.", instruction: "These are events which turn out in line without expectations of how the Universe behaves. To varying degrees, these are the parts of our experience which we have some element of control.", article: a6, order: 2
s62 = Step.create! title: "Consider learning to be the process of integrating events from the realm of Chaos into your realm of Order.", instruction: "We learn through our inquisitiveness and interest in the unusual, the rare, the strange, or the weird. These are things we have encountered which currently live in our realm of Chaos. By modifying our conceptual framework under which we view the world, we can integrate this new information into our realm of Order.", article: a6, order: 3
s63 = Step.create! title: "Be wary of staying too near to the realm of Order - the conservative.", instruction: "For those who hold their views and opinions in too high regard are not sufficiently open to the new, to the novel. They cannot learn and grow. They stultify, they are easily bored. They become boring people. We may imagine a prehistoric individual too scared to approach a lava flow, and thus miss the opportunity to discover fire.", article: a6, order: 4
s64 = Step.create! title: "Be wary of stepping too far into the realm of Chaos - the radical.", instruction: "For those with no fear of the unknown, overly confident steps into the realm of Chaos can result in an overload of new information incomprehensible to their current framework of thinking. Imagine this individual's first encounter with a lava flow: fascinated by the heat, he or she may stick their hands in out of curiosity and suffer fatal injuries.", article: a6, order: 5
s65 = Step.create! title: "Optimal learning involves staying in the Goldilocks Zone of Order and Chaos.", instruction: "The balanced individual is able to judge the amount of chaos they are able to take on at a time, and integrate this into their understanding of the world. This is learning.", article: a6, order: 6

a7 = Article.create! title: "How to reduce violence in violent times", author: u0, description: "Disputes will naturally occur in any community. But without the rule of law disagreements can quickly escalate to violence and a cycle of revenge. In any fledgling community it will be necessary to set up a simple system of law as early as possible, specifically to take the freedom to violence away from the individual and invest it with the community.", category: c3, status: Article.statuses[:published]
i70 = Ingredient.create! description: "A body of law which restricts individual freedom to violence, and invests that power to the community at large.", article: a7, order: 1
s70 = Step.create! title: "A body of law which restricts individual freedom to violence, and invests that power to the community at large.", instruction: "A body of law which restricts individual freedom to violence, and invests that power to the community at large.", article: a7, order: 1

a8 = Article.create! title: "How to make wooden ‘tent’ pegs", author: u9, description: "Knowing how to make wooden pegs gives you a practical solution to all sorts of garden - and general outdoor - problems: how to secure your tent or gazebo if you’ve lost a few of the metal pegs; how to stretch a line when you’re marking out a geometric shape for your lawn or flower bed; how to support the family’s new tennis net. Have a go: it’s very satisfying.", category: c2, status: Article.statuses[:published]
i80 = Ingredient.create! description: "a small, well sharpened axe", article: a8, order: 1
i81 = Ingredient.create! description: "a small hacksaw or a multitool", article: a8, order: 2
i82 = Ingredient.create! description: "a wooden block (or large secure log) to work onto", article: a8, order: 3
i83 = Ingredient.create! description: "a small round log", article: a8, order: 4
i84 = Ingredient.create! description: "a pencil and ruler", article: a8, order: 5
s80 = Step.create! title: "Choosing the log", instruction: "You should choose a straight grained hard wood,  25-30 cm in length & about 10cm in diameter, ideally ash or chestnut.", article: a8, order: 1
s81 = Step.create! title: "Preparation", instruction: "Hold the log upright on your block. Mark the top surface, using a pencil and ruler, with three intersecting straight lines to create 6 equal wedge shapes.", article: a8, order: 2
s82 = Step.create! title: "Make the first split", instruction: "Place the axe blade along one of the pencil lines. Now holding the blade securely against the log lift both together and tap firmly onto the block until the blade ‘bites’. Repeat the firm tapping until the blade splits the log cleanly in two.", article: a8, order: 3
s83 = Step.create! title: "Repeat the process", instruction: "Now repeat, dividing each of those pieces into three using your pencil lines as guides. Hey presto, six equal pieces.", article: a8, order: 4
s84 = Step.create! title: "Sharpen", instruction: "Use your axe blade to shave one end of each piece into a point.", article: a8, order: 5
s85 = Step.create! title: "Make the notch", instruction: "Use the hacksaw, or the saw on your multitool, to create a notch on each peg, which will help to keep your guy rope or string secure.The notch should be flat along its top edge.", article: a8, order: 6
s86 = Step.create! title: "Hey Presto!", instruction: "You will soon find that this process speeds up as you develop your confidence and skill to split the wood quickly - and as you find more reasons to make lots of pegs!", article: a8, order: 7

a2 = Article.create! title: 'Extract salt from sea water by evaporation', author: u0, description: 'Salt is a key mineral, and when it happens, you will need to find a way to produce your own salt.', category_id: c1.id, status: Article.statuses[:published]
s20 = Step.create! title: 'Soak the paper or cloth in sea water', instruction: 'This will make the collection of the salt crystals easier.', article_id: a2.id, order: 1
s21 = Step.create! title: 'Lay out to dry in the sun for a few days', article_id: a2.id, order: 2
s22 = Step.create! title: 'Collect the salt crystals', article_id: a2.id, order: 3
i20 = Ingredient.create! description: 'paper or cloth', article_id: a2.id, order: 1

a1 = Article.create! title: 'Making a decision', author: u1, category_id: c5.id, description: 'So, hands up, I’ve just stolen this from an interview/masterclass with Gary Oldman (referred to by my brother as Gary Old Man – and now I can’t think of him any other way). I believe – although it was not clear – that he was talking about the process for preparing for a role. I think this level of self-awareness has universal value. As a note: if Gary would like to write his own at any stage then I would of course be happy to defer to him. (<a href="https://www.youtube.com/watch?v=P0z55EaiLjI" target="_blank">@ 15:10</a>)', status: Article.statuses[:published]
s10 = Step.create! title: 'Rejection', article_id: a1.id, order: 1
s11 = Step.create! title: 'Denial', article_id: a1.id, order: 2
s12 = Step.create! title: 'Procrastination', article_id: a1.id, order: 3
s13 = Step.create! title: 'Acceptance (or surrender)', article_id: a1.id, order: 4
i10 = Ingredient.create! description: 'A challenge or problem', article_id: a1.id, order: 1
i11 = Ingredient.create! description: 'Good faith', article_id: a1.id, order: 2
i12 = Ingredient.create! description: 'Time', article_id: a1.id, order: 3

a0 = Article.create! title: 'Make a cup of coffee', author: u0, description: 'Caffine is very important in getting you going in the morning and contains many rare nutrients which you can\'t get anywhere else.', category_id: c1.id, status: Article.statuses[:published]
s0 = Step.create! title: 'Boil the water', article_id: a0.id, order: 1
s1 = Step.create! title: 'Put the coffee powder in the cup', article_id: a0.id, order: 2
s2 = Step.create! title: 'Pour in the boiling water', article_id: a0.id, order: 3
s3 = Step.create! title: 'Add the sugar', instruction: 'Don\'t put the milk in first, as the sugar melts better in the boiling water.', article_id: a0.id, order: 4
s4 = Step.create! title: 'Add the milk and stir', article_id: a0.id, order: 5
i0 = Ingredient.create! description: 'A kettle', article_id: a0.id, step_ids: [s0.id], order: 1
i1 = Ingredient.create! description: 'A cup', article_id: a0.id, step_ids: [s1.id, s2.id, s3.id, s4.id], order: 2
i2 = Ingredient.create! description: 'A spoon', article_id: a0.id, step_ids: [s1.id, s4.id], order: 3
i3 = Ingredient.create! description: 'Water', article_id: a0.id, step_ids: [s0.id, s2.id], order: 4
i4 = Ingredient.create! description: 'Coffee powder', article_id: a0.id, step_ids: [s1.id], order: 5
i5 = Ingredient.create! description: 'Milk', article_id: a0.id, step_ids: [s4.id], order: 6
i6 = Ingredient.create! description: 'Sugar', article_id: a0.id, step_ids: [s3.id], order: 7

Rating.all.destroy_all

Article.all.each do |a|
  User.all.shuffle.first(1+rand(User.all.count-1)).each do |u|
  	unless u==a.author
  	  View.create! user: u, article: a
  	  Rating.create! user: u, article: a, rating: [0.2,0.4,0.6,0.8,1.0].sample
  	end  
  end
end

Article.all.each { |a| Article.reset_counters a.id, :views }
Article.all.each { |a| Article.reset_counters a.id, :ratings }
Article.all.each { |a| a.update_ranking }
User.all.each { |u| User.reset_counters u.id, :articles }







