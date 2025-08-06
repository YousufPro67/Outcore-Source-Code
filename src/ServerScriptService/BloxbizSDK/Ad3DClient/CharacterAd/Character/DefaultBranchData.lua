return [[
       {
          "Branch4":{
             "BranchOptions":[
                {
                   "Text":"That was good.",
                   "Event":{
                      "Name":"Reward",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch5"
                },
                {
                   "Text":"Ugh, that was bad.",
                   "Event":{
                      "Name":"Survey",
                      "Data":{
                         "NoEmoji":true
                      }
                   },
                   "Next":"Branch5"
                },
                {
                   "Text":"Tell me another.",
                   "Event":{
                      "Name":"Survey",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch5"
                },
                {
                   "Text":"👋 Goodbye",
                   "Event":{
                      "Name":"Exit",
                      "Data":[
                         
                      ]
                   },
                   "Next":""
                }
             ],
             "Text":"A library!"
          },
          "Branch9":{
            "BranchOptions":[
               {
                  "Text":"Strongly Disagree",
                  "Event":{
                     "Name":"Exit",
                     "Data":[
                        
                     ]
                  },
                  "Next":""
               },
               {
                  "Text":"Disagree",
                  "Event":{
                     "Name":"Exit",
                     "Data":[
                        
                     ]
                  },
                  "Next":""
               },
               {
                  "Text":"Undecided",
                  "Event":{ 
                     "Name":"Exit",
                     "Data":[
                        
                     ]
                  },
                  "Next":""
               },
               {
                  "Text":"Agree",
                  "Event":{
                     "Name":"Exit",
                     "Data":[
                        
                     ]
                  },
                  "Next":""
               },
               {
                "Text":"Strongly Agree",
                "Event":{
                   "Name":"Exit",
                   "Data":[
                      
                   ]
                },
                "Next":"Branch1"
             }
            ],
            "Text":"Should devex rates be increased?"
         },
          "Branch1":{
             "BranchOptions":[
                {
                   "Text":"Who are you?",
                   "Event":{
                      "Name":"Reward",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch2"
                },
                {
                   "Text":"Tell me a riddle.",
                   "Event":{
                      "Name":"Survey",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch3"
                },
                {
                   "Text":"Tell me a joke.",
                   "Event":{
                      "Name":"Survey",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch6"
                },
                {
                   "Text":"👋 Goodbye",
                   "Event":{
                      "Name":"Survey",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch9"
                }
             ],
             "Text":"Hi there."
          },
          "Branch7":{
             "BranchOptions":[
                {
                   "Text":"That was funny.",
                   "Event":{
                      "Name":"Reward",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch8"
                },
                {
                   "Text":"Ugh, that was bad.",
                   "Event":{
                      "Name":"Survey",
                      "Data":{
                         "NoEmoji":true
                      }
                   },
                   "Next":"Branch8"
                },
                {
                   "Text":"Tell me another.",
                   "Event":{
                      "Name":"Survey",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch8"
                },
                {
                   "Text":"👋 Goodbye",
                   "Event":{
                      "Name":"Exit",
                      "Data":[
                         
                      ]
                   },
                   "Next":""
                }
             ],
             "Text":"Between us, something smells."
          },
          "Branch3":{
             "BranchOptions":[
                {
                   "Text":"Tell me.",
                   "Event":{
                      "Name":"Reward",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch4"
                },
                {
                   "Text":"I know the answer.",
                   "Event":{
                      "Name":"Survey",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch4"
                }
             ],
             "Text":"Which building has the most stories?"
          },
          "Branch8":{
             "BranchOptions":[
                {
                   "Text":"Yes, tell me a riddle.",
                   "Event":{
                      "Name":"Reward",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch3"
                },
                {
                   "Text":"Who are you?",
                   "Event":{
                      "Name":"Survey",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch2"
                },
                {
                   "Text":"No, goodbye.",
                   "Event":{
                      "Name":"Exit",
                      "Data":[
                         
                      ]
                   },
                   "Next":""
                }
             ],
             "Text":"That's the only joke I have, but want to hear a riddle?"
          },
          "Branch6":{
             "BranchOptions":[
                {
                   "Text":"What?",
                   "Event":{
                      "Name":"Reward",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch7"
                }
             ],
             "Text":"What did the left eye say to the right eye?"
          },
          "Branch5":{
             "BranchOptions":[
                {
                   "Text":"Yes, tell me a joke.",
                   "Event":{
                      "Name":"Reward",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch6"
                },
                {
                   "Text":"Who are you?",
                   "Event":{
                      "Name":"Survey",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch2"
                },
                {
                   "Text":"No, goodbye.",
                   "Event":{
                      "Name":"Exit",
                      "Data":[
                         
                      ]
                   },
                   "Next":""
                }
             ],
             "Text":"That's the only riddle I have, but want to hear a joke?"
          },
          "Branch2":{
             "BranchOptions":[
                {
                   "Text":"Ok...",
                   "Event":{
                      "Name":"Reward",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch1"
                },
                {
                   "Text":"Tell me a riddle.",
                   "Event":{
                      "Name":"Survey",
                      "Data":{
                         "NoEmoji":true
                      }
                   },
                   "Next":"Branch3"
                },
                {
                   "Text":"Tell me a joke.",
                   "Event":{
                      "Name":"Survey",
                      "Data":[
                         
                      ]
                   },
                   "Next":"Branch6"
                },
                {
                   "Text":"Ok, goodbye",
                   "Event":{
                      "Name":"Exit",
                      "Data":[
                         
                      ]
                   },
                   "Next":""
                }
             ],
             "Text":"I'm an experiment by Bloxbiz. We're working on some new technology."
          }
       }
    ]]