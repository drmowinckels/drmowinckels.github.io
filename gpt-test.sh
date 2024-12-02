#!bin/bash

curl 'https://api-inference.huggingface.co/models/HuggingFaceTB/SmolLM2-1.7B-Instruct/v1/chat/completions' \
-H "Authorization: Bearer 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" \
-H 'Content-Type: application/json' \
--data '{
    "model": "HuggingFaceTB/SmolLM2-1.7B-Instruct",
    "messages": [
		{
			"role": "user",
			"content": "Summarise the following text: Introducing the ggseg R-package for brain segmentations---  Introducing the ggseg R-package for brain segmentations Introducing the ggseg R-package for brain segmentations**Edit**: Though posted only a week ago, we have discovered another R package called `ggBrain` which has slightly different functions than what our package has. Because of this, we have altered the name of our package to `ggseg` short for `ggsegmentation` which is a better description of what our package does. Introducing the ggseg R-package for brain segmentations  Introducing the ggseg R-package for brain segmentations"
		}
	],
    "max_tokens": 500,
    "stream": false
}'

