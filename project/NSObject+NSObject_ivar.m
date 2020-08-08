//
//  NSObject+NSObject_ivar.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/6.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "NSObject+NSObject_ivar.h"

@implementation NSObject (NSObject_ivar)

- (NSString *) qCustomDescription
{
    static int depth = 0;

    NSMutableString *resultString = [NSMutableString stringWithFormat: @"<%@: %p>", NSStringFromClass([self class]), self];

    uint32_t ivarCount;
    Ivar *ivars = class_copyIvarList([self class], &ivarCount);

    if( ivars )
    {
        ++depth;
        [resultString appendString: @"\n"];

        for( int tabs = depth; --tabs > 0; )
            [resultString appendString: @"\t"];

        [resultString appendString: @"{"];

        for( uint32_t i = 0; i < ivarCount; ++i )
        {
            Ivar ivar = ivars[i];
            const char* type = ivar_getTypeEncoding(ivar);
            const char* ivarName = ivar_getName( ivar );
            NSString* valueDescription = @"";
            NSString* name = [NSString stringWithCString: ivarName encoding: NSASCIIStringEncoding];
            
            NSLog(@"%@====%s", name, type);

            switch( type[0] )
            {
                case '@':
                {
                    id v = object_getIvar(self, ivar);
                    if( v )
                    {
                        if( [self respondsToSelector: @selector(qDescriptionForValue:)] )
                            valueDescription = [self performSelector: @selector(qDescriptionForValue:) withObject: v];
                        else
                            valueDescription = [v description];
                    }
                    break;
                }

                case 'c':
                {
                    char v = ((char (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%c", v];
                    break;
                }

                case 'i':
                {
                    int v = ((int (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%i", v];
                    break;
                }

                case 's':
                {
                    short v = ((short (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%d", v];
                    break;
                }

                case 'l':
                {
                    long v = ((long (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%ld", v];
                    break;
                }

                case 'q':
                {
                    long long v = ((long long (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%lld", v];
                    break;
                }

                case 'C':
                {
                    unsigned char v = ((unsigned char (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%uc", v];
                    break;
                }

                case 'I':
                {
                    unsigned int v = ((unsigned int (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%u", v];
                    break;
                }

                case 'S':
                {
                    unsigned short v = ((unsigned short (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%u", v];
                    break;
                }

                case 'L':
                {
                    unsigned long v = ((unsigned long (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%lu", v];
                    break;
                }

                case 'Q':
                {
                    unsigned long long v = ((unsigned long long (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%llu", v];
                    break;
                }

                case 'f':
                {
                    float v = ((float (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%f", v];
                    break;
                }

                case 'd':
                {
                    double v = ((double (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%f", v];
                    break;
                }

                case 'B':
                {
                    BOOL v = ((BOOL (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%@", v ? @"YES" : @"NO"];
                    break;
                }

                case '*':
                {
                    char *v = ((char* (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"%s", v];
                    break;
                }

                case '#':
                {
                    id v = object_getIvar(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"Class: %s", object_getClassName(v)];
                    break;
                }

                case ':':
                {
                    SEL v = ((SEL (*)(id, Ivar))object_getIvar)(self, ivar);
                    valueDescription = [NSString stringWithFormat: @"Selector: %s", sel_getName(v)];
                    break;
                }

                case '[':
                case '{':
                case '(':
                case 'b':
                case '^':
                {
                    valueDescription = [NSString stringWithFormat: @"%s", type];
                    break;
                }

                default:
                    valueDescription = [NSString stringWithFormat: @"UNKNOWN TYPE: %s", type];
                    break;
            }

            [resultString appendString: @"\n"];

            for( int tabs = depth; --tabs >= 0; )
                [resultString appendString: @"\t"];

            [resultString appendFormat: @"%@: %@", name, valueDescription];
        }

        [resultString appendString: @"\n"];

        for( int tabs = depth; --tabs > 0; )
            [resultString appendString: @"\t"];

        [resultString appendString: @"}"];
        --depth;

        free(ivars);
    }

    return resultString;
}

@end
