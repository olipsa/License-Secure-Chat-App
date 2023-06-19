import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/theme.dart';

import '../../../states_management/onboarding/profile_image_cubit.dart';

class ProfileUpload extends StatelessWidget {
  const ProfileUpload({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 126.0,
        width: 126.0,
        child: Material(
            color: isLightTheme(context)
                ? const Color.fromARGB(255, 242, 242, 242)
                : const Color.fromARGB(255, 56, 52, 52),
            borderRadius: BorderRadius.circular(126.0),
            child: InkWell(
                borderRadius: BorderRadius.circular(126.0),
                onTap: () async {
                  await context.read<ProfileImageCubit>().getImage(context);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: BlocBuilder<ProfileImageCubit, File?>(
                          builder: (context, state) {
                            return state == null
                                ? Icon(
                                    Icons.person_outline_rounded,
                                    size: 126.0,
                                    color: isLightTheme(context)
                                        ? const Color.fromARGB(
                                            222, 181, 180, 180)
                                        : Colors.black,
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(126.0),
                                    child: Image.file(
                                      state,
                                      width: 126,
                                      height: 126,
                                      fit: BoxFit.fill,
                                    ),
                                  );
                          },
                        )
                        // child:
                        ),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.add_circle_rounded,
                          color: kPrimary, size: 38.0),
                    )
                  ],
                ))));
  }
}
