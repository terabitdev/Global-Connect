import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../Provider/FaqProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  final List<Map<String, String>> faqs = const [
    {
      'question': 'What exactly is Global Connect?',
      'answer':
          'Global Connect is the mobile app designed to help you explore the world in a new way. Find hidden local gems, exciting events, and meet new friends – whether you\'re traveling or just want to experience more in your own city. We\'re all about connecting you to authentic experiences and people.',
    },
    {
      'question': 'Who is this app perfect for?',
      'answer':
          "It's great for you if you love to travel, backpack, study abroad, or simply want to get to know your own city better and meet interesting people. Both adventurous souls and those seeking a sense of belonging will find their place here!",
    },
    {
      'question': 'Do I have to pay to use the app?',
      'answer':
          'No, Global Connect is free to download and use! We fund the app through collaborations with businesses that want to showcase their offers, and through other partners, so you can enjoy all core features at no cost.',
    },
    {
      'question': "What are Global Connect's main features?",
      'answer':
          "With Global Connect, you can:\n• Choose your 'travel mode': Decide whether you want to see content and chat with people globally, or only with those from your own home country.\n• Chat locally & privately: Participate in chats with everyone in the city you are in, or chat one-on-one and in private groups.\n• Find and share tips: Discover the best local tips on restaurants, places, and hidden gems – and share your own!\n• Browse events: See what's happening nearby, from concerts and festivals to social gatherings.\n• Review places: Read and leave reviews for restaurants, bars, and other spots you visit.\n• Show off your travels: Keep a personal profile with an interactive map showing all the countries you've visited.",
    },
    {
      'question':
          'What\'s the difference between "Countrymen" and "Global" mode?',
      'answer':
          'Countrymen Mode: Perfect for you if you want to meet and see content primarily from people of your own nationality while abroad. The local chat, for example, will only include countrymen.\nGlobal Mode: Opens up the app to everyone! Meet people from all over the world and see all available tips and events, regardless of nationality. You can easily switch between modes anytime within the app.',
    },
    {
      'question': 'Can I add events or recommend restaurants myself?',
      'answer':
          'You can definitely share your own tips and write reviews for restaurants and places you\'ve visited – that\'s a key part of the app! However, the official events and new restaurants are added by Global Connect administrators to ensure quality and relevance, often in collaboration with our partners.',
    },
    {
      'question': 'How does the local chat work?',
      'answer':
          'The local chat is a shared conversation for all Global Connect users who are physically present in the same city as you. You\'ll automatically join the chat for your current location and can only send messages there. The content within the local chat will also filter based on whether you\'ve selected "Countrymen" or "Global" mode.',
    },
    {
      'question': 'How does Global Connect protect my privacy?',
      'answer':
          'Your privacy is very important to us. We collect only data to provide and improve the app, personalize your experience, and offer you relevant promotions via our trusted partners. All data processing adheres to strict laws like GDPR. You always have control over your data and can read all details in our comprehensive Privacy Policy (which you can find via a link in the app under Settings/Privacy).',
    },
    {
      'question': 'I have a business and want to partner – how do I do that?',
      'answer':
          'Fantastic! We love connecting businesses with our engaged audience. Please visit the dedicated "Become a Partner" section on our website (www.global-connect.ai/partner) for more information and a simple contact form.',
    },
    {
      'question': 'I didn\'t find an answer to my question. Who can I contact?',
      'answer':
          'Still have questions or need help? Don\'t hesitate to contact us! You can send an email directly to contact@global-connect.ai. We\'re happy to help!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'FAQs',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth * 0.05,
            vertical: context.screenHeight * 0.02,
          ),
          child: Consumer<FaqProvider>(
            builder: (context, faqProvider, _) => Column(
              children: [
                ...List.generate(faqs.length, (index) {
                  final isExpanded = faqProvider.expandedIndex == index;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.garyModern200),
                      boxShadow: [
                        if (isExpanded)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          faqProvider.toggleIndex(index);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      faqs[index]['question']!,
                                      style: pjsStyleBlack16500.copyWith(
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0.0,
                                    duration: Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.keyboard_arrow_right_rounded,
                                      color: AppColors.garyModern400,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                SizedBox(height: 8),
                                Text(
                                  faqs[index]['answer']!,
                                  style: pStyleBlack14400.copyWith(
                                    color: AppColors.greyscale400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
